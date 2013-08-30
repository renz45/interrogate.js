/*
Interrogate.js Version: 0.0.1
*/

/*
The MIT License (MIT)

Copyright (c) 2013 Adam Rensel, Code School LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

(function() {
  window.Interrogate = {
    getVars: function(code) {
      var bodyItems, interrogateContext, parseTree, recordedVars, variableNames;

      parseTree = esprima.parse(code);
      variableNames = [];
      bodyItems = esprima.parse("interrogateContext()").body;
      estraverse.traverse(parseTree, {
        previousNode: false,
        leave: function(node) {
          if (this.previousNode && this.previousNode.type === 'ReturnStatement') {
            node.body.splice(node.body.indexOf(this.previousNode), 0, bodyItems);
            node.body = _.flatten(node.body);
          } else if (node.type === 'Program') {
            node.body.push(bodyItems);
            node.body = _.flatten(node.body);
          }
          return this.previousNode = node;
        },
        enter: function(node) {
          if (node.type === 'VariableDeclaration') {
            return _.each(node.declarations, function(declaration) {
              return variableNames.push(declaration.id.name);
            });
          } else if (node.type === 'AssignmentExpression') {
            return variableNames.push(node.left.name);
          } else if (node.type === 'VariableDeclarator') {
            if (node.init.type !== 'FunctionExpression') {
              return variableNames.push(node.id.name);
            }
          }
        }
      });
      recordedVars = {};
      interrogateContext = function() {
        var evaledValue, vName, _i, _len, _results;

        _results = [];
        for (_i = 0, _len = variableNames.length; _i < _len; _i++) {
          vName = variableNames[_i];
          evaledValue = eval(vName);
          if (typeof evaledValue !== 'undefined') {
            _results.push(recordedVars[vName] = evaledValue);
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };
      eval(this.guardLoops("" + (escodegen.generate(parseTree)) + ";"));
      return recordedVars;
    },
    safeEval: function(code, failureCallback, options) {
      if (options == null) {
        options = {};
      }
      return eval(this.guardLoops(code, failureCallback, options));
    },
    guardLoops: function(code, failureCallback, options) {
      var parseTree, tolerance, tryCatch;

      if (options == null) {
        options = {};
      }
      parseTree = esprima.parse(code);
      tolerance = options.tolerance || 100;
      tryCatch = "      try {      }catch(e){        if(failureCallback){          failureCallback(e)        }else{          throw e        }      }    ";
      estraverse.traverse(parseTree, {
        countId: 0,
        leave: function(node) {
          var loopsStatements,
            _this = this;

          loopsStatements = _.flatten([
            _.where(node.body, {
              type: "WhileStatement"
            }), _.where(node.body, {
              type: "ForStatement"
            }), _.where(node.body, {
              type: "ForInStatement"
            })
          ]);
          return _.each(loopsStatements, function(statement) {
            var errorThrowNode, errorThrowVariableNode, index, tryCatchNode;

            errorThrowVariableNode = esprima.parse("var _tryCount_" + _this.countId + " = 0;");
            errorThrowNode = esprima.parse("          _tryCount_" + _this.countId + " += 1;          if(_tryCount_" + _this.countId + " > " + tolerance + "){            throw 'Infinite" + statement.type + "LoopError';          }          ");
            statement.body.body.unshift(errorThrowNode);
            index = node.body.indexOf(statement);
            node.body.splice(index, 1);
            tryCatchNode = esprima.parse(tryCatch);
            tryCatchNode.body[0].block.body.push(errorThrowVariableNode, statement);
            node.body.splice(index, 0, tryCatchNode);
            return _this.countId += 1;
          });
        }
      });
      return escodegen.generate(parseTree);
    }
  };

}).call(this);
