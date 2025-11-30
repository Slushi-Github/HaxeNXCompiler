// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source;

import haxe.CallStack;

/**
 * Message types for logging.
 */
enum MsgType {
	INFO;
	SUCCESS;
	WARNING;
	ERROR;
	PROCESSING;
	NONE;
	DEBUG;
}

/**
 * Simple logging class
 * 
 * Author: Slushi
 */
class Logger {
	/**
	 * Prints a message to the terminal.
	 * @param text The text to print.
	 * @param alertType The type of message.
	 * @param prefix An optional prefix to add to the message.
	 */
	public static function log(text:Dynamic, alertType:MsgType, prefix:String = ""):Void {
		switch (alertType) {
			case ERROR:
				Sys.println(prefix + "\x1b[38;5;1m[ERROR]\033[0m " + text);
			case WARNING:
				Sys.println(prefix + "\x1b[38;5;3m[WARNING]\033[0m " + text);
			case SUCCESS:
				Sys.println(prefix + "\x1b[38;5;2m[SUCCESS]\033[0m " + text);
			case INFO:
				Sys.println(prefix + "\x1b[38;5;7m[INFO]\033[0m " + text);
			case PROCESSING:
				Sys.println(prefix + "\x1b[38;5;24m[PROCESSING]\033[0m " + text);
			case DEBUG:
				Sys.println(prefix + "\x1b[38;5;5m[DEBUG]\033[0m " + text);
			case NONE:
				Sys.println(prefix + text);
			default:
				Sys.println(text);
		}
	}

	/**
	 * Prints an error message to the terminal and exits the program.
	 * @param text The text to print.
	 * @param justExit Whether to just exit the program.
	 */
	public static function exitBecauseError(text:Dynamic, ?justExit:Bool = false):Void {
		if (justExit) {
			Sys.exit(1);
		}
		Sys.println("\x1b[38;5;1m[CANT CONTINUE]\033[0m " + text);
		Sys.exit(1);
	}


    /**
     * Prints a crash message to the terminal
     * @param e The error to print
     */
    public static function crashHandler(e:Dynamic):Void {
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

		log("\n/// CRASH ///\nHaxe call stack:\n"
			+ callStackText
			+ "\nError: "
			+ e
			+ "\n----------------\nPlease report this error in https://github.com/Slushi-Github/HaxeNXCompiler/issues\n",
			NONE);
	}
}