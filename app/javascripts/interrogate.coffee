window.Interrogate =
  getVars: (code)->
    parseTree = esprima.parse(code)
    # expressionStatement > left > name
    # VariableDeclaration > [0,1,2,3] > id > name
    variableNames = []
    bodyItems = esprima.parse("interrogateContext()").body

    estraverse.traverse parseTree,
      previousNode: false
      leave: (node)->
        if this.previousNode && this.previousNode.type == 'ReturnStatement'
          node.body.splice(node.body.indexOf(this.previousNode),0, bodyItems)
          node.body = _.flatten(node.body)
        else if node.type == 'Program'
          node.body.push(bodyItems)
          node.body = _.flatten(node.body)
        this.previousNode = node

      enter: (node)->
        if node.type == 'VariableDeclaration'
          _.each node.declarations, (declaration)->
            variableNames.push(declaration.id.name)
        else if node.type == 'AssignmentExpression'
          variableNames.push(node.left.name)
        else if node.type == 'VariableDeclarator'
          if node.init.type != 'FunctionExpression'
            variableNames.push(node.id.name)

    recordedVars = {};
    interrogateContext = ->
      for vName in variableNames
        evaledValue = eval(vName)
        if typeof(evaledValue) != 'undefined'
          recordedVars[vName] = evaledValue

    eval(@guardLoops("#{escodegen.generate(parseTree)};"))

    recordedVars

  safeEval: (code, failureCallback, options={})->
    eval(@guardLoops(code, failureCallback, options))

  guardLoops: (code, failureCallback, options={})->
    parseTree = esprima.parse(code)
    # Set how many times a loop is allowed to loop before being considered infinite
    tolerance = options.tolerance || 100

    # setup try catch code which we'll turn into parse trees on demand
    # I think it's more efficient to do that then try to clone the parsetree
    # everytime you need a copy of it
    getTryCatchTree = ()->
      tryCatch = "
        try {

        }catch(e){
          var failureCallback;
          if(failureCallback){
            failureCallback(e)
          }else{
            throw e
          }
        }
      "
      tryCatchTree = esprima.parse(tryCatch)
      # insert the callback function passed into the guardloops method
      if failureCallback
        tryCatchTree.body[0].handlers[0].body.body[0] = esprima.parse(failureCallback.toString()).body[0]

      tryCatchTree

    # Traverse through the parse tree looking for loops
    estraverse.traverse parseTree,
      countId: 0
      leave: (node)->
        # search each node for while and for statements (loops)
        loopsStatements = _.flatten([
          _.where(node.body, {type: "WhileStatement"})
          _.where(node.body, {type: "ForStatement"})
          _.where(node.body, {type: "ForInStatement"})
        ])

        # For each loops statement found wrap it in a try catch and inject some error throwing code
        _.each loopsStatements, (statement)=>
          # create the _tryCount_<id> variable to hold the loop count and parse it into a parse tree node
          errorThrowVariableNode = esprima.parse("var _tryCount_#{@countId} = 0;")

          # create the code that throws an error on too many loops and turn it into a parse tree node
          errorThrowNode = esprima.parse("
          _tryCount_#{@countId} += 1;
          if(_tryCount_#{@countId} > #{tolerance}){
            throw 'Infinite#{statement.type}LoopError';
          }
          ")

          # inject the error throwing code into the loop statement, splice the loop from the node
          statement.body.body.unshift(errorThrowNode)
          index = node.body.indexOf(statement)
          node.body.splice(index, 1)

          # turn the trycatch code into a parse tree and inject the loop code into the try block
          tryCatchNode = getTryCatchTree()
          tryCatchNode.body[0].block.body.push(errorThrowVariableNode,statement)

          # splice the trycatch code back into the original code in the correct position
          node.body.splice(index, 0, tryCatchNode)

          # increment the @countId so the _tryCount_ variables are always unique
          @countId += 1

    escodegen.generate(parseTree)