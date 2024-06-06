package haxe;

import haxe.bson.BsonDecoder;
import haxe.bson.BsonEncoder;
import haxe.io.Bytes;

class Bson {
	public static inline function encode(o:Dynamic):Bytes {
		return BsonEncoder.encode(o);
	}

	public static inline function encodeMultiple(o:Array<Dynamic>):Bytes {
		return BsonEncoder.encodeMultiple(o);
	}

	public static inline function decode(b:Bytes):Dynamic {
		return BsonDecoder.decode(b);
	}

	public static inline function decodeMultiple(b:Bytes, n = 1):Dynamic {
		return BsonDecoder.decodeMultiple(b, n);
	}
}