module.exports =
    provide: ->
        path = require 'path'
        fs = require 'fs'
        CSON = require 'season'
        require 'string_score'
        provider =
            selector: '.source.pig'
            disableForSelector: '.source.pig .comment'
            inclusionPriority: 1
            excludeLowerPriority: true

            getPrefix:(editor, bufferPosition)->
                regex = /::([\$\w0-9_-]+)$|\)\s*:(\w+)$|(:[\$\w0-9_-]+)$|([\$\w0-9_-]+)$/
                line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
                match = line.match regex
                return '' unless match
                return match[4] || match[3] || match[2] || match[1] || match[0]

            getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
                new Promise (resolve) ->
                    suggestions = []
                    basics = CSON.parse(fs.readFileSync(path.join(__dirname, 'suggestions/basic.cson')))
                    keywords = CSON.parse(fs.readFileSync(path.join(__dirname, 'suggestions/keyword.cson')))
                    types = CSON.parse(fs.readFileSync(path.join(__dirname, 'suggestions/type.cson')))
                    funcs = CSON.parse(fs.readFileSync(path.join(__dirname, 'suggestions/func.cson')))
                    datetimes = CSON.parse(fs.readFileSync(path.join(__dirname, 'suggestions/datetime.cson')))
                    storages = CSON.parse(fs.readFileSync(path.join(__dirname, 'suggestions/storage.cson')))
                    prefix = provider.getPrefix editor, bufferPosition
                    Buffer = editor.getBuffer()
                    Text = Buffer.getText()
                    if prefix
                        for name, keyword of keywords when beginWith(prefix, keyword.text)
                            suggestions.push
                                type: 'keyword'
                                text: keyword.text
                                score: keyword.text.score(prefix)
                        for name, type of types when beginWith(prefix, type.text)
                            suggestions.push
                                type: 'type'
                                text: type.text
                                score: type.text.score(prefix)
                        for name, basic of basics when beginWith(prefix, basic.displayText)
                            suggestions.push
                                type: 'keyword'
                                displayText: basic.displayText
                                snippet: basic.snippet
                                description: basic.description
                                descriptionMoreURL: 'http://pig.apache.org/docs/r0.14.0/basic.html#' + name
                                score: basic.displayText.score(prefix)
                        for name, datetime of datetimes when beginWith(prefix, datetime.displayText)
                            suggestions.push
                                iconHTML: '<i class="icon-calendar"></i>'
                                type: 'function'
                                displayText: datetime.displayText
                                snippet: datetime.snippet
                                description: datetime.description
                                descriptionMoreURL: 'http://pig.apache.org/docs/r0.14.0/func.html#' + name
                                score: datetime.displayText.score(prefix)
                        for name, storage of storages when beginWith(prefix, storage.displayText)
                            suggestions.push
                                iconHTML: '<i class="icon-move-down"></i>'
                                type: 'function'
                                displayText: storage.displayText
                                snippet: storage.snippet
                                description: storage.description
                                descriptionMoreURL: 'http://pig.apache.org/docs/r0.14.0/func.html#' + name
                                score: storage.displayText.score(prefix)
                        for name, func of funcs when beginWith(prefix, func.displayText)
                            suggestions.push
                                type: 'function'
                                displayText: func.displayText
                                snippet: func.snippet
                                description: func.description
                                descriptionMoreURL: 'http://pig.apache.org/docs/r0.14.0/func.html#' + name
                                score: func.displayText.score(prefix)

                    suggestions.sort (a,b)=>
                        b.score - a.score
                    resolve(suggestions)

beginWith = (str1, str2) ->
    if str2 and str1
        str1 = str1.toLowerCase()
        str2 = str2.toLowerCase()
        str2.includes(str1)
