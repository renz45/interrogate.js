$ ->
  # window.givenCode = givenCode = $('body script').text().replace(/\/\/<!\[CDATA\[/, '').replace(/\/\/\]\]>\n/, '')

  # $('.original').text(givenCode)

  # window.parseTree = esprima.parse(givenCode)

  # window.convertedCode = escodegen.generate(parseTree)

  # $('.converted').text(convertedCode)

  getVars = (code)->
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

    eval("#{escodegen.generate(parseTree)};")
    recordedVars

  console.log(getVars("
  var b = 'hello everyone!';
  var a = 123456;
  c = {one: 1, two: 2};
  var d = function(){
    return 'hello';
  };
  arr = [1,2,3,4,5];

  for(i in arr){
    console.log(b + ' - ' + arr[i]);
  };
  "))