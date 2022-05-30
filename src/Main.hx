package;
import sys.io.File;
using Interlude;
using Lexer;
using Utils;

class Main {
    public static function main() {
        var fileName = './demo/hello-world.hx';
        // read files
        var file = File.getContent(fileName);
        trace(file);

        // to lines
        var lines = file.lines();

        // lexer
        var tokens = [
            for(index => line in lines)
                Lexer.lex(fileName, index+1, line)
        ].flatten();

        // parser
        // transforms
        // write output
        //trace(tokens);
        for(token in tokens.mapS(TokenExtensions.prettyPrint)) {
            trace(token);
        }
    }
}