package;

using Interlude;
using String;
using Lexer;
using Utils;

@:publicFields
class Lexer {
    static var ident_char = ~/[a-zA-Z0-9_']/;
    static var num_char = ~/[0-9_\.]/;
    static var indentChar = '';
    static var indentCharPerLevel = 1;

    static function lex(fileName:String, lineNum:UInt, input:String):Array<Token> {
        var it = input.iterator().peekable();//keyValueIterator().peekable();
        var indent = it.peekWhile(x -> x.isSpace(0));
        var column = indent.length + 1;
        if(indent.any() && indentChar == '') {
            indentChar = indent[0];
            indentCharPerLevel = indent.takeWhile(x -> x == indentChar).count();
        }
        var indentLevel = Math.floor(indent.takeWhile(x -> x == indentChar).count() / indentCharPerLevel);

        function currentPos():Position return mkPos(fileName, lineNum, column);
        function mkTokens(kind:TokenKind, text:String, ?increment:Int) return [{
            var out = mkToken(currentPos(), indentLevel, kind, text);
            if(increment != null)
                column += increment;
            else
                column += text.length;
            out;
        }];

        return [
            for (value in it) {
                var char = value.fromCharCode();
                switch (char) {
                    case OpenParen | CloseParen
                       | OpenBrace | CloseBrace
                       | OpenBracket | CloseBracket
                       | Comma | Backslash | Bar | Underscore:
                        mkTokens(SpecialChar(char), char);
                    case ForwardSlash if(it.nextIfChar(ForwardSlash).any()):
                        mkTokens(Comment, it.toIterable().mapS(String.fromCharCode).join(''));
                    case Colon if (it.nextIfChar(':').any()):
                        mkTokens(SpecialChar(DoubleColon), '::');
                    case Colon:
                        mkTokens(SpecialChar(Colon), char);
                    case Quote:
                        var str = ''; // ignore first quote
                        while(!it.peek().match(None | Some(_.fromCharCode() => '"'))) {
                            str += it.next().fromCharCode();
                        }
                        if(it.peek().match(None))
                            throw '${currentPos()} - Unterminated string $str';
                        it.next(); // ignore matching quote
                        mkTokens(Constant(CString, str), str, 1+str.length);
                    case Minus if (it.nextIfChar('>').any()):
                        mkTokens(SpecialChar(SmallArrow), SmallArrow);
                    case Minus:
                        mkTokens(SpecialChar(Minus), Minus);
                    case Equals if (it.nextIfChar('>').any()):
                        mkTokens(SpecialChar(BigArrow), BigArrow);
                    case Equals:
                        mkTokens(SpecialChar(Equals), Equals);
                    case '.':
                        switch([it.nextIfChar('.'), it.nextIfChar('.'), it.nextIfChar('.')]) {
                            case [Some(_), Some(_), None]:
                                mkTokens(SpecialChar(Ellipsis), '...');
                            case [a, b, c]:
                                var tail = [a, b, c].somes().toArray().join('');
                                throw '${currentPos()} - Unrecognized ".$tail"';
                        }
                    case ' ':
                        column++;
                        [];
                    case '\n' | '\r':
                        column++;
                        mkTokens(NewLine, char);
                    //case x if(num_char.match(x)):throw '${currentPos()} hmm $x';
                    case _:
                        if(num_char.match(char)) {
                            var str = char;
                            var kind = CInt;
                            while(it.hasNext()) {
                                switch(it.nextIf(num_char.match)) {
                                    case Some(c) if(c == '.' && kind != CFloat):
                                        kind = CFloat;
                                        str += c;
                                    case Some(c) if(c == '.' && kind == CFloat):
                                        throw '${currentPos()} - Unexpected "."';
                                    case Some(c):
                                        str += c;
                                    case None: break;
                                }
                            }
                            mkTokens(Constant(kind, str.replace(Underscore, '')), str);
                        }
                        else if (ident_char.match(char)) {
                            var str = char;

                            while (it.hasNext()) {
                                switch (it.nextIf(ident_char.match)) {
                                    case Some(c): str = str + c;
                                    case None: break;
                                }
                            }

                            switch (str) {
                                case Print | Todo
                                   | Extend
                                   | Matches | Match | With
                                   | Implements | This | Template
                                   | Let | In:
                                    mkTokens(Keyword(str), str);
                                default:
                                    mkTokens(Identifier, str);
                            }
                        } else {
                            trace('OOPS: $char');
                            mkTokens(Identifier, char);
                        }
                }
            }
        ].flatten().append(mkTokens(NewLine, '\n')).toArray();
    }

    inline static function mkToken(pos:Position, indent:UInt, kind:TokenKind, text:String):Token return {
        kind: kind,
        text: text,
        indent: indent,
        pos: pos
    }

    inline static function mkPos(fileName:String, lineNum:UInt, column:UInt):Position return {
        fileName: fileName,
        line: lineNum,
        column: column
    }
}

typedef Position = {
    final fileName:String;
    final line:UInt;
    final column:UInt;
}

typedef Token = {
    final kind:TokenKind;
    final text:String;
    final indent:UInt;
    final pos:Position;
}

enum TokenKind {
    Identifier;
    Comment;
    NewLine;
    Constant(kind:ConstantType, value:String);
    Keyword(value:KeywordToken);
    SpecialChar(value:SpecialCharToken);
}

enum ConstantType {
    CString;
    CInt;
    CFloat;
}

enum abstract KeywordToken(String) from String to String {
    final Print      = 'trace';
    final Todo       = 'todo';
    final Extend     = 'extend';
    final Matches    = 'matches';
    final Match      = 'match';
    final With       = 'with';
    final Implements = 'implements';
    final This       = 'this';
    final Template   = 'template';
    final Let        = 'let';
    final In         = 'in';
}

enum abstract SpecialCharToken(String) from String to String {
    final OpenParen    = '(';
    final CloseParen   = ')';
    final OpenBrace    = '{';
    final CloseBrace   = '}';
    final OpenBracket  = '[';
    final CloseBracket = ']';
    final Quote        = '"';
    final Comma        = ',';
    final Backslash    = '\\'; // actually a single \
    final ForwardSlash = '/';
    final Bar          = '|';
    final Underscore   = '_';
    final Colon        = ':';
    final DoubleColon  = '::';
    final Ellipsis     = '...';
    final SmallArrow   = '->';
    final BigArrow     = '=>';
    final Equals       = '=';
    final Minus        = '-';
}

@:publicFields
class TokenExtensions {
    static function toString(token:Token):String {
        //return '$token' + '\n';
        return '${token.indent} | ' + (switch token.kind {
            case Identifier           : 'Ident ${token.text}';
            case Comment              : 'Commt ${token.text}';
            case Constant(kind, value): 'Const $kind $value';
            case Keyword(value)       : 'KeyWd $value';
            case SpecialChar(value)   : 'SpChr $value';
            case NewLine              : 'NewLn';
            //case _                    : throw 'TODO: $token';
        });
    }

    static function prettyPrint(token:Token):String {
        var indent = '  '.replicate(token.indent).toArray().join('');
        var expr = switch token.kind {
            case Identifier           : token.text;
            case Comment              : '// ${token.text}';
            case Constant(kind, value): value;
            case Keyword(value)       : value;
            case SpecialChar(value)   : value;
            case NewLine              : '\\n';
        }
        return indent + expr;
    }
}