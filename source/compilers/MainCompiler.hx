// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.compilers;

/**
 * The MainCompiler class is used to compile the Haxe project and then link the nintendo Switch files.
 * 
 * Author: Slushi
 */
class MainCompiler {
	public static var haxeCompiler:HaxeCompiler = null;
    public static var nxLinker:NXLinker = null;

    public static function startCompiler(...args:Dynamic):Void {
        ProjectFile.init().load();
		new LibsManager();
        new AssetsManager();

        final principalArg:String = args[0]?.toLowerCase() ?? "";
        final secondArg:String = args[1]?.toLowerCase() ?? "";

		if (principalArg.toLowerCase() == "--debug") {
			HaxeCompiler.forceDebugMode = true;
		} else if (principalArg == "--clean") {
			CommandLineUtils.cleanBuild();
		}

        haxeCompiler = new HaxeCompiler();
        haxeCompiler.startCompiler();
        if (haxeCompiler.getExitCode() != 0) {
            return;
        }
        AssetsManager.instance.processAssets();
        nxLinker = new NXLinker();
        nxLinker.startCompiler();

		// Send the .nro file to the Nintendo Switch after compilation
		if (haxeCompiler.getExitCode() == 0 && nxLinker.getExitCode() == 0) {
			if (ProjectFile.instance.config.sendAfterCompile || (principalArg != null
				&& (principalArg == "--send")
				|| secondArg != null
				&& (secondArg == "--send"))) {
				DevKitProUtils.send("--server");
			}
		}
    }
}