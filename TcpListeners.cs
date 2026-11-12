using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;

namespace DevPorts
{
    public sealed class TcpListenerInfo
    {
        public string Address { get; private set; }
        public int Port { get; private set; }
        public uint ProcessId { get; private set; }

        internal TcpListenerInfo(IPAddress address, uint networkPort, uint processId)
        {
            Address = address.ToString();
            Port = unchecked((ushort)IPAddress.NetworkToHostOrder((short)networkPort));
            ProcessId = processId;
        }
    }

    public static class TcpListeners
    {
        private const int OwnerPidListener = 3; // TCP_TABLE_OWNER_PID_LISTENER
        private const uint InsufficientBuffer = 122;

        // Windows SDK layouts for MIB_TCPROW_OWNER_PID and MIB_TCP6ROW_OWNER_PID.
        [StructLayout(LayoutKind.Sequential)]
        private struct Tcp4Row
        {
            public uint State;
            public uint LocalAddress;
            public uint LocalPort;
            public uint RemoteAddress;
            public uint RemotePort;
            public uint ProcessId;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct Tcp6Row
        {
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
            public byte[] LocalAddress;
            public uint LocalScopeId;
            public uint LocalPort;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
            public byte[] RemoteAddress;
            public uint RemoteScopeId;
            public uint RemotePort;
            public uint State;
            public uint ProcessId;
        }

        [DllImport("iphlpapi.dll", ExactSpelling = true)]
        private static extern uint GetExtendedTcpTable(
            IntPtr table, ref int size, bool ordered, AddressFamily family, int tableClass, uint reserved);

        public static List<TcpListenerInfo> GetAll()
        {
            var listeners = new List<TcpListenerInfo>();
            ReadTable<Tcp4Row>(AddressFamily.InterNetwork, row =>
                new TcpListenerInfo(new IPAddress(BitConverter.GetBytes(row.LocalAddress)),
                    row.LocalPort, row.ProcessId), listeners);
            ReadTable<Tcp6Row>(AddressFamily.InterNetworkV6, row =>
                new TcpListenerInfo(new IPAddress(row.LocalAddress,
                    unchecked((uint)IPAddress.NetworkToHostOrder((int)row.LocalScopeId))),
                    row.LocalPort, row.ProcessId), listeners);
            return listeners;
        }

        private static void ReadTable<TRow>(
            AddressFamily family, Func<TRow, TcpListenerInfo> decode, List<TcpListenerInfo> listeners)
            where TRow : struct
        {
            int size = 0;
            uint error = GetExtendedTcpTable(IntPtr.Zero, ref size, false, family, OwnerPidListener, 0);

            // The number of listeners can grow between the size probe and the read.
            for (int attempt = 0; attempt < 4 && error == InsufficientBuffer; attempt++)
            {
                IntPtr table = Marshal.AllocHGlobal(size);
                try
                {
                    error = GetExtendedTcpTable(table, ref size, false, family, OwnerPidListener, 0);
                    if (error != 0)
                    {
                        continue;
                    }

                    // A DWORD row count precedes the array. Both row types are DWORD-aligned.
                    int count = Marshal.ReadInt32(table);
                    int rowSize = Marshal.SizeOf<TRow>();
                    for (int index = 0; index < count; index++)
                    {
                        IntPtr row = IntPtr.Add(table, sizeof(uint) + index * rowSize);
                        listeners.Add(decode(Marshal.PtrToStructure<TRow>(row)));
                    }
                    return;
                }
                finally
                {
                    Marshal.FreeHGlobal(table);
                }
            }

            throw new Win32Exception((int)error, "Could not read the Windows TCP listener table (error " + error + ").");
        }
    }
}
