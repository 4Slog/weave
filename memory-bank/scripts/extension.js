// Memory Bank VSCode Extension
// This extension automatically tracks code changes and updates memory-bank files

const vscode = require('vscode');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    console.log('Memory Bank extension is now active');

    // Register commands
    const trackCommand = vscode.commands.registerCommand('memory-bank.track', () => {
        trackChanges('manual');
    });

    const enableCommand = vscode.commands.registerCommand('memory-bank.enable', () => {
        const config = vscode.workspace.getConfiguration('memory-bank');
        config.update('autoTrack', true, true);
        vscode.window.showInformationMessage('Memory Bank: Auto-tracking enabled');
    });

    const disableCommand = vscode.commands.registerCommand('memory-bank.disable', () => {
        const config = vscode.workspace.getConfiguration('memory-bank');
        config.update('autoTrack', false, true);
        vscode.window.showInformationMessage('Memory Bank: Auto-tracking disabled');
    });

    context.subscriptions.push(trackCommand, enableCommand, disableCommand);

    // Register file save event listener
    const saveListener = vscode.workspace.onDidSaveTextDocument((document) => {
        const config = vscode.workspace.getConfiguration('memory-bank');
        if (config.get('autoTrack') && config.get('trackOnSave')) {
            // Check if the file should be excluded
            const excludePatterns = config.get('excludePatterns');
            const relativePath = vscode.workspace.asRelativePath(document.uri);
            
            const shouldExclude = excludePatterns.some(pattern => {
                if (pattern.endsWith('/**')) {
                    const dir = pattern.slice(0, -3);
                    return relativePath.startsWith(dir);
                }
                return relativePath.match(new RegExp(pattern.replace(/\*/g, '.*')));
            });

            if (!shouldExclude) {
                trackChanges('save', relativePath);
            }
        }
    });

    context.subscriptions.push(saveListener);
}

/**
 * Track code changes
 * @param {string} trigger - What triggered the tracking (manual, save, commit)
 * @param {string} [filePath] - The path of the file that triggered the tracking
 */
function trackChanges(trigger, filePath = null) {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
        vscode.window.showErrorMessage('Memory Bank: No workspace folder found');
        return;
    }

    const rootPath = workspaceFolders[0].uri.fsPath;
    const scriptPath = path.join(rootPath, 'memor-bank', 'scripts', 'auto_track.dart');

    // Check if the script exists
    if (!fs.existsSync(scriptPath)) {
        vscode.window.showErrorMessage(`Memory Bank: Script not found at ${scriptPath}`);
        return;
    }

    // Build the command
    let command = `cd "${rootPath}" && dart "${scriptPath}" ${trigger}`;
    if (filePath) {
        command += ` "${filePath}"`;
    }

    // Execute the command
    exec(command, (error, stdout, stderr) => {
        if (error) {
            vscode.window.showErrorMessage(`Memory Bank: Error tracking changes - ${error.message}`);
            console.error(`Memory Bank error: ${error.message}`);
            return;
        }

        if (stderr) {
            console.error(`Memory Bank stderr: ${stderr}`);
        }

        console.log(`Memory Bank stdout: ${stdout}`);
        
        // Show a status bar message
        vscode.window.setStatusBarMessage('Memory Bank: Changes tracked', 3000);
    });
}

function deactivate() {
    console.log('Memory Bank extension is now deactivated');
}

module.exports = {
    activate,
    deactivate
};
