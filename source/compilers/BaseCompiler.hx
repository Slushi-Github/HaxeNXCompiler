// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.compilers;

/**
 * Base class for all compilers
 * 
 * Author: Slushi
 */
class BaseCompiler {
    /**
     * The exit code of this compiler
     */
    public var exitCode:Null<Int> = 0;

    public function new() {}

    /**
     * Start the compiler
     */
    public function startCompiler(...args:Dynamic):Void {}

	/**
     * Get the exit code of this compiler
	 * @return Int
	 */
	public function getExitCode():Null<Int> {
		return exitCode;
	}
}