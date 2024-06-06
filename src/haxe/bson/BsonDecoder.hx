package haxe.bson;

import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.bson.BsonType;

using Reflect;

class BsonDecoder {
	
	public static inline function decode(b:Bytes):Dynamic {
		return new BsonInput(b).readObject();
	}
	
	public static inline function decodeMultiple(b:Bytes, num = 1):Array<Dynamic> {
		var input = new BsonInput(b);
		return [for(i in 0...num) input.readObject()];
	}
}

private class BsonInput extends BytesInput {
	
	public function readObject():Dynamic {
		var length = readInt32() - 4; // exclude the 32-bit length value
		var o = {};
		while(length > 0) {
			var type = readByte();
			length --;
			if(type == BTerminate)
				return o;
			var field = readField(type);
			o.setField(field.key, field.value);
			length -= field.length;
		}
		return o;
	}
	
	public function readArray():Array<Dynamic> {
		var length = readInt32() - 4; // exclude the 32-bit length value
		var array = [];
		while(length > 0) {
			var type = readByte();
			length --;
			if(type == BTerminate)
				return array;
			var field = readField(type);
			array[Std.parseInt(field.key)] = field.value;
			length -= field.length;
		}
		return array;
	}
	
	public function readField(type:BsonType) {
		var startPos = position;
		var key = readUntil(BTerminate);
		var value:Dynamic = switch type {
			
			case BDouble:
				readDouble();
			
			case BString | BJavascript:
				var len = readInt32();
				var v = readString(len - 1);
				readByte(); // consume terminator
				v;
			
			case BDocument:
				readObject();
			
			case BArray:
				readArray();
			
			case BBinary:
				var len = readInt32();
				var subtype:BsonSubType = readByte();
				read(len);
			
			case BObjectId:
				(read(12):ObjectId);
				
			case BBool:
				readByte() == 1;
				
			case BDate:
				Date.fromTime(readUInt64());
				
			case BNull:
				null;
				
			case BRegEx:
				var pattern = readUntil(BTerminate);
				var options = readUntil(BTerminate);
				new EReg(pattern, options);
				
			case BJavascriptWithScope:
				throw 'not implemented';
				
			case BInt32:
				readInt32();
				
			case BTimestamp:
				readInt64();
				
			case BInt64:
				// var v = readInt64();
				// v.high * 4294967296.0 + (v.low > 0 ? v.low : 4294967296.0 + v.low);
				readInt64();
				
			case BMinKey:
				'Min';
				
			case BMaxKey:
				'Max';
				
			default:
				throw 'Unkown type: $type';
		}
		
		return {
			key: key,
			value: value,
			length: position - startPos,
		}
	}
	
	public function readInt64() {
		var low = readInt32();
		var high = readInt32();
		return Int64.make(high, low);
	}
	public function readUInt32():UInt {
		var low = readInt16() & 0xffff;
		var high = readInt16() & 0xffff;
		return low + high * 65536;
	}
	public function readUInt64() {
		var low = readUInt32();
		var high = readUInt32();
		return low + high * 4294967296.0;
	}
}


