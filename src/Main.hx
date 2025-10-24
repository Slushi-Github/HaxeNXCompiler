// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package src;

import haxe.CallStack;

import src.SlushiUtils;
import src.compilers.MainCompiler;
import src.utils.DevKitProUtils;

/**
 * The Main class is the entry point of the HaxeNXCompiler program.
 * It handles the command line arguments and starts the compilation process.
 * 
 * This program is based on HxCompileU v1.5.5 
 * ... Well, if something already works, why redo it? I'm not going to redo 
 * something that has a similar function to HxCompileU.
 * 
 * Author: Slushi
 */
class Main {
	public static var haxenxcompilerString = "\x1b[38;5;214mHaxe\033[0m\x1b[38;5;81mN\x1b[38;5;1mX\033[0mCompiler (Based on \x1b[38;5;214mHx\033[0mCompile\x1b[38;5;74mU\033[0m)";
	public static final version:String = "2.0.0";
	static var stdin = Sys.stdin();
	static var stdout = Sys.stdout();
	static var args = Sys.args();

	public static function main() {
		try {
			if (args.length < 1) {
				SlushiUtils.printMsg("No arguments, use --help for more information", NONE);
				return;
			}

			if (args[0] != "--version" || args[0] != "--v" || args[0] != "--help" || args[0] != "--h" || args.length < 1) {
				SlushiUtils.printMsg('$haxenxcompilerString v$version -- Created by \033[96mSlushi\033[0m', NONE);
			}

			if (JsonFile.checkJson() == false) {
				return;
			}

			switch (args[0]) {
				case "--prepare" | "--p":
					JsonFile.createJson();
				case "--import" | "--i":
					JsonFile.importJSON(args[1]);
				case "--compile" | "--c":
					MainCompiler.start(args[1], args[2]);
				case "--searchProblem" | "--sp":
					DevKitProUtils.searchProblem(args[1]);
				case "--send" | "--s":
					DevKitProUtils.send(args[1]);
				case "--help" | "--h":
					SlushiUtils.printMsg("Usage: HaxeNXCompiler [command]\nCommands:\n\t--prepare, --p: Creates a new haxeNXConfig.json in the current directory.\n\t--import, --i \033[3mHAXE_LIB\033[0m: Imports a JSON file from a Haxe lib to the current directory \n\t--compile, --c: Compiles the project. \n\t\tAdd \"--debug\" to enable Haxe debug mode \n\t--searchProblem, --sp \033[3mLINE_ADDRESS\033[0m: search for a line of code in the [.elf] file from a line address of some log using devkitA64's aarch64-none-elf-addr2line program \n\t--send, --s: Sends the .nro file to the Nintendo Switch using DevKitPro's nxlink program \n\t\tAdd \"--server\" or \"--s\" to start the a cosnole server via nxlink\n\t--version, --v: Shows the version of the compiler\n\t--help, --h: Shows this message",
						NONE);
				default:
					SlushiUtils.printMsg("Invalid argument: [" + args.join(" ") + "], use \033[3m--help\033[0m argument for more information", NONE);
					return;
			}
		} catch (e) {
			var callStackText:String = "";
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);

			for (stackItem in callStack) {
				switch (stackItem) {
					case FilePos(s, file, line, column):
						if (callStackText == "") {
							// Underline only the first line
							callStackText += "\033[4m" + file + "#" + line + "\033[24m\n";
						} else {
							callStackText += file + "#" + line + "\n";
						}
					case CFunction:
						callStackText += "Non-Haxe (C) Function";
					case Module(c):
						callStackText += 'Module ${c}';
					default:
						callStackText += "Unknown stack item";
				}
			}

			SlushiUtils.printMsg("\n/// CRASH ///\nHaxe call stack:\n"
				+ callStackText
				+ "\nError: "
				+ e
				+ "\n----------------\nPlease report this error in https://github.com/Slushi-Github/HaxeNXCompiler/issues\n", NONE);
		}
	}
}
