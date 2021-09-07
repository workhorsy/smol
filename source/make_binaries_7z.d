// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z


module make_binaries_7z;

import helpers;

int g_scope_depth = 0;
string compression_level = "-mx9";
string compression_multi_thread = "-mmt=on";



enum FileType {
	Zip,
	SevenZip,
	Binary,
}

FileType getFileType(string name) {
	import std.stdio : File;

	// Read first 10 bytes of file
	auto f = File(name, "r");
	char[10] header = 0;
	f.rawRead(header);

	// Return file type based on magic numbers
	if (header[0 .. 4] == [0x50, 0x4B, 0x03, 0x04]) {
		return FileType.Zip;
	} else if (header[0 .. 6] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]) {
		return FileType.SevenZip;
	} else {
		return FileType.Binary;
	}
}

string getScopePadding() {
	import std.range : repeat, take;
	import std.array : array, join;
	return "    ".repeat.take(g_scope_depth).array.join("");
}

void recompressFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();
/*
	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}
*/
	string full_path = absolutePath(name);
	string path = pathDirName(full_path);
	string file_name = pathBaseName(full_path);
	string temp_dir = "%s.xxx".format(file_name);
	string out_file = "%s.7z".format(file_name);
	string prev_dir = getcwd().absolutePath();

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, file_name);
	chdir(path);
	uncompress(file_name, temp_dir);

	recompressDir(temp_dir, false);

	// Compress to 7z
	prints("%sCompressing: %s", padding, out_file);
	chdir(temp_dir);
	compress("*", "../%s".format(out_file), FileType.SevenZip);
	chdir("..");

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original zip file
	if (exists(file_name)) {
		remove(file_name);
	}

	chdir(prev_dir);
}

void unRecompressFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format, stripRight;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();
/*
	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}
*/
	string full_path = absolutePath(name);
	string path = pathDirName(full_path);
	string file_name = pathBaseName(full_path);
	string temp_dir = "%s.xxx".format(file_name);
	string out_file = "%s.zip".format(file_name.stripRight(".zip.7z"));
	string prev_dir = getcwd().absolutePath();

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, file_name);
	chdir(path);
	uncompress(file_name, temp_dir);

	unRecompressDir(temp_dir, false);

	// Compress to 7z
	prints("%sCompressing: %s", padding, out_file);
	chdir(temp_dir);
	compress("*", "../%s".format(out_file), FileType.Zip);
	chdir("..");

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original 7z file
	if (exists(file_name)) {
		remove(file_name);
	}

	chdir(prev_dir);
}

void recompressDir(string path, bool is_root_dir) {
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir, remove, exists;
	import std.string : format;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	foreach (string name; dirEntries(path, SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		//prints("%sScanning: %s", padding, name);

		if (isDir(name)) continue;

		auto file_type = getFileType(name);
		final switch (file_type) {
			case FileType.SevenZip:
				break;
			case FileType.Zip:
				recompressFile(name);
				break;
			case FileType.Binary:
				if (is_root_dir) {
					string prev_dir = getcwd().absolutePath();
					string dir_name = pathDirName(name);
					string file_name = pathBaseName(name);
					//prints("!!!!! dir_name: %s", dir_name);
					//prints("!!!!! file_name: %s", file_name);
					chdir(dir_name);
					compress(file_name, "%s.7z".format(file_name), FileType.SevenZip);
					chdir(prev_dir);

					// Delete the original binary file
					if (exists(name)) {
						remove(name);
					}
				}
				break;
		}
	}
}

void unRecompressDir(string path, bool is_root_dir) {
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir;
	import std.algorithm.searching : endsWith;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	foreach (string name; dirEntries(path, SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		//prints("%sScanning: %s", padding, name);

		if (isDir(name) || ! name.endsWith(".7z")) continue;

		auto file_type = getFileType(name);
		final switch (file_type) {
			case FileType.SevenZip:
				unRecompressFile(name);
				break;
			case FileType.Zip:
				break;
			case FileType.Binary:
				break;
		}
	}
}

void compress(string in_name, string out_name, FileType file_type) {
	import std.process : execute;
	import std.string : format;
	import std.file : isDir;
	import std.array : join;

	string compression_type;
	final switch (file_type) {
		case FileType.Zip:
			compression_type = "-tZip";
			break;
		case FileType.SevenZip:
			compression_type = "-t7z";
			break;
		case FileType.Binary:
			compression_type = "";
			break;
	}

	//prints("%sCompressing: %s", padding, out_name);
	string[] command = ["7z", compression_type, compression_level, compression_multi_thread, "a", out_name, in_name];
	//prints("Running command: %s", command.join(" "));
	auto exe = execute(command);
	if (exe.status != 0) {
		prints_error("%s", exe.output);
	}
	assert(exe.status == 0);
}

void uncompress(string in_name, string out_name) {
	import std.process : execute;
	import std.string : format;
	import std.array : join;

	string[] command = ["7z", "x", in_name, "-o%s".format(out_name)];
	//prints("Running command: %s", command.join(" "));
	auto exe = execute(command);
	if (exe.status != 0) {
		prints_error("%s", exe.output);
	}
	assert(exe.status == 0);
}
