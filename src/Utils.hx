package;

using Interlude;
using interlude.iter.IteratorTools;
using String;
using Utils;

@:publicFields
class Utils {
    static function nextIfChar<T>(it:PeekableIterator<Int>, match:String):Option<String> return
        switch(it.peek()) {
            case Some(x) if(x.fromCharCode() == match): {
                it.next();
                Some(match);
            }
            default: None;
        }

    static function nextIf(it:PeekableIterator<Int>, predicate:String->Bool):Option<String> return
        switch (it.peek()) {
            case Some(_.fromCharCode() => x) if(predicate(x)):
                it.next();
                Some(x);
            default: None;
        }

    static function peekWhile(it:PeekableIterator<Int>, predicate:String->Bool):Array<String> return [
        while (true) {
            switch (it.nextIf(predicate)) {
                case Some(c): c;
                default     : break;
            }
        }
    ];

    static function lines(str:String):Array<String> return str
        .split('\r\n')
        .flatMap(sub -> sub.split('\r'))
        .flatMap(sub -> sub.split('\n'))
        .toArray();
}