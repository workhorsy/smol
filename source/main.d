// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z



import make_binaries_7z;


int main(string[] args) {
	import std.file : exists;
	import std.getopt : getopt;
	import helpers : pathDirName, toPosixPath, absolutePath, prints, prints_error;

	// Change the dir to the location of the current exe
	//chdir(pathDirName(args[0]));

	// Get the options
	string pack_path = null;
	string unpack_path = null;
	bool is_help = false;
	string getopt_error = null;
	try {
		auto result = getopt(args,
		"pack", &pack_path,
		"unpack", &unpack_path);
		is_help = result.helpWanted;
	} catch (Exception err) {
		getopt_error = err.msg;
		is_help = true;
	}

	// If there was an error, print the help and quit
	if (is_help) {
		prints_error(
		"Make Binaries 7z\n" ~
		"--pack            Directory to re compress. Required:\n" ~
		"--unpack          Directory to un re compress. Required:\n" ~
		"--help            This help information.\n");

		if (getopt_error) {
			prints_error("Error: %s", getopt_error);
		}
		return 1;
	}

	// Make sure we got path to pack
	if (pack_path) {
		pack_path = toPosixPath(pack_path);
		if (! exists(pack_path)) {
			prints_error(`Error: pack path not found: %s`, pack_path);
			return 1;
		}
	}

	// Make sure we got path to unpack
	if (unpack_path) {
		unpack_path = toPosixPath(unpack_path);
		if (! exists(unpack_path)) {
			prints_error(`Error: unpack path not found: %s`, unpack_path);
			return 1;
		}
	}

	// Pack or unpack the dir
	if (pack_path) {
		//prints("!!! pack_path: %s", pack_path);
		recompressDir(pack_path, true);
	} else if (unpack_path) {
		//prints("!!! unpack_path: %s", unpack_path);
		unRecompressDir(unpack_path, true);
	} else {
		prints_error(`Error: unpack or pack path required`);
		return 1;
	}

	return 0;
}