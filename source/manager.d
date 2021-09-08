// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

import global;
import helpers;
import messages;
import json;
import structs;

import std.concurrency : Tid, thisTid, spawn, receive;
import core.thread.osthread : Thread;
import core.time : dur;
import std.variant : Variant;
import dlib.serialization.json : JSONObject, JSONValue, JSONType;


class Manager {
	bool _is_running = false;

	this() {
		onMessages("manager", ulong.max, cast(void*) this, function(void* data, string message_type, JSONObject jsoned) {
			Manager self = cast(Manager) data;
			switch (message_type) {
				case "MessageStop":
					auto message = jsoned.jsonToStruct!MessageStop();
					self._is_running = false;
					return self._is_running;
				default:
					prints_error("!!!! (manager) Unexpected message: %s", jsoned.jsonToString());
			}

			return true;
		});
	}
}
