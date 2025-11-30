// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source;

/**
 * The main class of the program
 */
class Main {
	/**
     * The version of the program
	 */
	public static final VERSION:String = "3.0.0";

	/**
	 * The name of the program colored with ANSI escape codes
	 */
	public static final haxenxcompilerString:String = "\x1b[38;5;214mHaxe\033[0m\x1b[38;5;81mN\x1b[38;5;1mX\033[0mCompiler";

    /**
     * The arguments passed to the program
     */
	static final args:Array<String> = Sys.args();

    /**
     * embedded list of commands with their description
     */
    private static var commandsInfo(get, never):String;

    /**
     * Main entry point, just that
     */
    public static function main():Void {
        try {
			if (args.length < 1) {
				Logger.log("No arguments, use \033[3m--help\033[0m for more information", NONE);
				return;
			}

            final principalArg:String = args[0].toLowerCase();
            final secondArg:String = args[1].toLowerCase();
            final thirdArg:String = args[2].toLowerCase();

			if (principalArg != "--help" && principalArg != "-h" && principalArg != "--version" && principalArg != "-v") {
				Logger.log('$haxenxcompilerString v$VERSION -- Created by \033[96mSlushi\033[0m', NONE);
			}

            ///////////////////////////////

            #if HX_NX
			Logger.log("What are you doing XD?!", NONE);
            #end

            // Commands
            switch (principalArg) {
                case "--prepare" | "-p":
                    ProjectFile.createExample();
                case "--import" | "-i":
                    ProjectFile.importFromLibrary(secondArg);
                case "--compile" | "-c":
                    MainCompiler.startCompiler(secondArg, thirdArg);
                case "--send" | "-s":
                    DevKitProUtils.send(secondArg);
				case "--crashAnalyzer" | "-ca":
                    CrashAnalyzer.initWithFile();
                case "--help" | "-h":
                    Logger.log(commandsInfo, NONE);
                case "--version" | "-v":
					Logger.log('$haxenxcompilerString v$VERSION -- Created by \033[96mSlushi\033[0m\nThe project that lets you use Haxe on a Nintendo Switch!\nProject released under the \x1b[38;5;231mMIT License\033[0m \nGitHub: \x1b[38;5;75mhttps://github.com/Slushi-Github/HaxeNXCompiler\033[0m', NONE);
                default:
                    Logger.log("Invalid argument [" + principalArg + "] use \033[3m--help\033[0m for more information", NONE);
            }
        }
        catch (e) {
            Logger.crashHandler(e);
        }
    }

    /////////////////////////////////

    private static function get_commandsInfo():String {
		return Resource.getString("CommandsInfo");
    }
}