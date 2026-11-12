using System;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("devports")]
[assembly: AssemblyProduct("devports")]
[assembly: AssemblyDescription("Inspect local TCP listeners on Windows")]
[assembly: AssemblyVersion("0.1.0.0")]
[assembly: AssemblyFileVersion("0.1.0.0")]

internal static class Launcher
{
    [STAThread]
    private static int Main()
    {
        try
        {
            using (var runspace = RunspaceFactory.CreateRunspace())
            {
                runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                runspace.Open();

                using (var shell = PowerShell.Create())
                {
                    shell.Runspace = runspace;
                    InvokeResource(shell, "DevPorts.Core.ps1");
                    InvokeResource(shell, "devports-gui.ps1");
                }
            }
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show("无法启动 devports。\n\n" + error.Message, "devports",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    private static void InvokeResource(PowerShell shell, string name)
    {
        string source;
        using (var stream = typeof(Launcher).Assembly.GetManifestResourceStream(name))
        {
            if (stream == null)
            {
                throw new InvalidOperationException("Missing embedded resource: " + name);
            }

            using (var reader = new StreamReader(stream))
            {
                source = reader.ReadToEnd();
            }
        }

        // Both scripts share a runspace so the GUI can call the core functions.
        shell.AddScript(source, useLocalScope: false);
        shell.Invoke();
        if (shell.HadErrors)
        {
            throw new InvalidOperationException(shell.Streams.Error[0].ToString());
        }
        shell.Commands.Clear();
    }
}
