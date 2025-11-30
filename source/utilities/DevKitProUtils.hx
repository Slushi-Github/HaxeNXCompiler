// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.utilities;

/**
 * The DevKitProUtils class is used to use the DevKitPro tools.
 * 
 * Author: Slushi.
 */
class DevKitProUtils {
	/**
	 * Searches for a problem in the code from a line address.
	 * @param address The address to search for.
	 */
	public static function searchProblem(address:String):Void {
		if (address == null || address == "") {
			Logger.exitBecauseError("Invalid address");
			return;
		}

		if (ProjectFile.instance == null) {
			ProjectFile.init().load();
		}

		var elfPath:String = CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/switchFiles/"
			+ ProjectFile.instance.config.switchProjectName + ".elf";
		if (!FileSystem.exists(elfPath)) {
			Logger.exitBecauseError("[.elf] file not found");
			return;
		}

		var devKitProEnv = Sys.getEnv("DEVKITPRO");
		var addr2lineProgram:String = devKitProEnv + "/devkitA64/bin/aarch64-none-elf-addr2line";

		if (devKitProEnv == null) {
			Logger.exitBecauseError("DEVKITPRO environment variable not found");
		}
		else if (!FileSystem.exists(addr2lineProgram)) {
			Logger.exitBecauseError("aarch64-none-elf-addr2line program not found");
		}

		Logger.log("If the output is \"??:0\", the address does not exist or is invalid", NONE);
		Logger.log("----------------------", NONE);
		Sys.command(addr2lineProgram, ["-e", elfPath, address]);
		Logger.log("----------------------", NONE);
	}

	/**
	 * Sends the compiled .nro file to the Switch console.
	 */
	public static function send(arg1:String):Void {
		if (ProjectFile.instance == null) {
			ProjectFile.init().load();
		}
		var filePath:String = CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/switchFiles/"
			+ProjectFile.instance.config.switchProjectName + ".nro";

		if (!FileSystem.exists(filePath)) {
			Logger.exitBecauseError("NRO file not found");
			return;
		}

		var fileSizeMB:Float = Math.round((FileSystem.stat(filePath).size / 1024.0 / 1024.0) * 100) / 100; // MB
		var fileName:String = Path.withoutDirectory(filePath);

		Logger.log("Sending file: [" + fileName + "] (" + fileSizeMB + " MB)", PROCESSING);

		var devKitProToolsEnv = Sys.getEnv("DEVKITPRO");
		var nxlinkProgram = devKitProToolsEnv + "/tools/bin/nxlink";

		if (devKitProToolsEnv == null) {
			Logger.exitBecauseError("DEVKITPRO environment variable not found");
		}
		else if (!FileSystem.exists(nxlinkProgram)) {
			Logger.exitBecauseError("nxlink program not found");
		}

		var arguments = ["-a", ProjectFile.instance.config.switchConsoleIP, filePath];

		if (arg1.toLowerCase() == "--server" || arg1.toLowerCase() == "-s") {
			arguments.push("-s");
		}

		Sys.command(nxlinkProgram, arguments);
	}
}