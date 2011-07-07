using System;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections;
using System.Management;
using System.Threading;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Xml.XPath;

namespace nVentoryRegisterClient
{
    class Program
    {
        static void Main(string[] args)
        {
            register();
        }

        static void register()
        {
            // The key=value parts of the HTTP body that we will POST/PUT to nVentory
            ArrayList bodyParts = new ArrayList();

            ManagementObjectSearcher searcher;
            ManagementObjectCollection collection;
            IEnumerator enumerator;

            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_SystemEnclosure");
            collection = searcher.Get();
            enumerator = collection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject win32SystemEnclosure = (ManagementObject)enumerator.Current;

            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_ComputerSystem");
            collection = searcher.Get();
            enumerator = collection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject win32ComputerSystem = (ManagementObject)enumerator.Current;

            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_ComputerSystemProduct");
            collection = searcher.Get();
            enumerator = collection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject win32ComputerSystemProduct = (ManagementObject)enumerator.Current;

            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_BaseBoard");
            collection = searcher.Get();
            enumerator = collection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject win32BaseBoard = (ManagementObject)enumerator.Current;

            // There will be multiple Win32_Processor results on multi-CPU boxes
            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_Processor");
            ManagementObjectCollection processorCollection = searcher.Get();
            enumerator = processorCollection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject firstWin32Processor = (ManagementObject)enumerator.Current;

            // There's a Win32_PhysicalMemory result for each memory stick
            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_PhysicalMemory");
            ManagementObjectCollection memoryCollection = searcher.Get();
            
            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_OperatingSystem");
            collection = searcher.Get();
            enumerator = collection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject win32OperatingSystem = (ManagementObject)enumerator.Current;

            searcher = new ManagementObjectSearcher("SELECT * FROM Win32_TimeZone");
            collection = searcher.Get();
            enumerator = collection.GetEnumerator();
            enumerator.MoveNext();
            ManagementObject win32TimeZone = (ManagementObject)enumerator.Current;

            // Hostname
            String name = win32OperatingSystem["CSName"].ToString();
            if ((bool) win32ComputerSystem["PartOfDomain"])
            {
                name = name + "." + win32ComputerSystem["Domain"].ToString();
            }
            bodyParts.Add("node[name]=" + Uri.EscapeDataString(name));

            // Operating system
            String osManufacturer = win32OperatingSystem["Manufacturer"].ToString();
            osManufacturer = Regex.Replace(osManufacturer, "Microsoft Corporation", "Microsoft");
            bodyParts.Add("operating_system[vendor]=" + Uri.EscapeDataString(osManufacturer));
            String osCaption = win32OperatingSystem["Caption"].ToString();
            if (osCaption.StartsWith("Microsoft Windows "))
            {
                bodyParts.Add("operating_system[variant]=Windows");
                String osVersion = Regex.Replace(osCaption, "Microsoft Windows ", "");
                bodyParts.Add("operating_system[version_number]=" + Uri.EscapeDataString(osVersion));
            }
            else
            {
                bodyParts.Add("operating_system[variant]=" + Uri.EscapeDataString(osCaption));
            }
            bodyParts.Add("operating_system[architecture]=" + Uri.EscapeDataString(win32OperatingSystem["OSArchitecture"].ToString()));
            bodyParts.Add("node[kernel_version]=" + Uri.EscapeDataString(win32OperatingSystem["BuildNumber"].ToString()));

            // General hardware info
            String hwManufacturer = "Unknown";
            // It isn't clear to me which order of preference to use between
            // Win32_SystemEnclosure and Win32_ComputerSystem.  Order here
            // chosen mostly at random.  So far I haven't seen them return
            // different answers, but I have seen one have data and the other
            // not have data.
            if (win32SystemEnclosure["Manufacturer"] != null)
            {
                hwManufacturer = win32SystemEnclosure["Manufacturer"].ToString();
            }
            else if (win32ComputerSystem["Manufacturer"] != null)
            {
                hwManufacturer = win32ComputerSystem["Manufacturer"].ToString();
            }
            bodyParts.Add("hardware_profile[manufacturer]=" + Uri.EscapeDataString(hwManufacturer));
            String hwModel = "Unknown";
            if (win32SystemEnclosure["Model"] != null)
            {
                hwModel = win32SystemEnclosure["Model"].ToString();
            }
            else if (win32ComputerSystem["Model"] != null)
            {
                hwModel = win32ComputerSystem["Model"].ToString();
            }
            bodyParts.Add("hardware_profile[model]=" + Uri.EscapeDataString(hwModel));
            bodyParts.Add("node[serial_number]=" + Uri.EscapeDataString(win32SystemEnclosure["SerialNumber"].ToString()));
            String uniqueID = win32ComputerSystemProduct["UUID"].ToString();
            bodyParts.Add("node[uniqueid]=" + Uri.EscapeDataString(uniqueID));
            if (win32SystemEnclosure["NumberOfPowerCords"] != null)
            {
                bodyParts.Add("node[power_supply_count]=" + Uri.EscapeDataString(win32SystemEnclosure["NumberOfPowerCords"].ToString()));
            }

            // CPUs
            bodyParts.Add("node[processor_manufacturer]=" + Uri.EscapeDataString(firstWin32Processor["Manufacturer"].ToString()));
            bodyParts.Add("node[processor_model]=" + Uri.EscapeDataString(firstWin32Processor["Name"].ToString()));
            // CurrentClockSpeed isn't ideal because it can vary if dynamic
            // frequency scaling is in use.  However in my experience the
            // MaxClockSpeed reported by the hardware has no relation to
            // reality.
            bodyParts.Add("node[processor_speed]=" + Uri.EscapeDataString(firstWin32Processor["CurrentClockSpeed"].ToString()) + " MHz");
            bodyParts.Add("node[processor_count]=" + Uri.EscapeDataString(processorCollection.Count.ToString()));
            UInt32 coreCount = 0;
            foreach (ManagementObject win32Processor in processorCollection)
            {
                coreCount += (UInt32)win32Processor["NumberOfCores"];
            }
            bodyParts.Add("node[processor_core_count]=" + Uri.EscapeDataString(coreCount.ToString()));
            // Haven't yet figured out a way to get the CPU socket count
            // node[processor_socket_count]
            bodyParts.Add("node[os_processor_count]=" + Uri.EscapeDataString(win32ComputerSystem["NumberOfProcessors"].ToString()));
            bodyParts.Add("node[os_virtual_processor_count]=" + Uri.EscapeDataString(win32ComputerSystem["NumberOfLogicalProcessors"].ToString()));

            // Memory
            UInt64 totalMemory = 0;
            ArrayList memorySizes = new ArrayList();
            foreach (ManagementObject win32Memory in memoryCollection)
            {
                // Exclude types that aren't RAM
                UInt16 memoryType = (UInt16)win32Memory["MemoryType"];
                if (memoryType == 10 || // ROM
                    memoryType == 11 || // Flash
                    memoryType == 12 || // EEPROM
                    memoryType == 13 || // FEPROM
                    memoryType == 14)   // EPROM
                {
                    continue;
                }
                UInt64 capacityInMegs = (UInt64)win32Memory["Capacity"] / 1024 / 1024;
                totalMemory += capacityInMegs;
                memorySizes.Add(capacityInMegs.ToString());
            }
            bodyParts.Add("node[physical_memory]=" + Uri.EscapeDataString(totalMemory.ToString()));
            // FIXME: Coalesce like the unix perl client so this doesn't become a long, hard to view string on boxes with lots of sticks of memory
            // I.e. 1024,1024,1024,1024,2048,2048 becomes 4@1024,2@2048
            bodyParts.Add("node[physical_memory_sizes]=" + Uri.EscapeDataString(String.Join(",", (String[])memorySizes.ToArray(typeof(String)))));
            UInt64 osMemoryInMegs = (UInt64)win32OperatingSystem["TotalVisibleMemorySize"] / 1024;
            bodyParts.Add("node[os_memory]=" + Uri.EscapeDataString(osMemoryInMegs.ToString()));
            bodyParts.Add("node[swap]=" + Uri.EscapeDataString(win32OperatingSystem["SizeStoredInPagingFiles"].ToString()));

            bodyParts.Add("node[timezone]=" + Uri.EscapeDataString(win32TimeZone["Caption"].ToString()));

            // node[virtualarch]
            // node[virtualmode]

            // NICs and IPs?

            String body = String.Join("&", (String[])bodyParts.ToArray(typeof(String)));
            Console.WriteLine("body: " + body);

            // If we load this from a config file we need to make sure it ends in a /
            String server = "http://nventory/";
            WebRequest request;

            // FIXME: just for testing
            System.Net.ServicePointManager.ServerCertificateValidationCallback += delegate(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
            {
                // Return true to force the certificate to be accepted.
                return true;
            };

            String nodeID = null;

            // Search server for entry matching unique ID
            if (uniqueID != null && uniqueID != "")
            {
                request = WebRequest.Create(server + "nodes.xml?exact_node[uniqueid]=" + Uri.EscapeUriString(uniqueID));
                HttpWebResponse response = (HttpWebResponse)request.GetResponse();
                if (response.StatusCode == HttpStatusCode.OK)
                {
                    XPathDocument document = new XPathDocument(response.GetResponseStream());
                    XPathNavigator navigator = document.CreateNavigator();
                    XPathNavigator node = navigator.SelectSingleNode("/nodes/node/id");
                    if (node != null)
                    {
                        nodeID = node.Value;
                        Console.WriteLine("Node ID from unique ID search: " + nodeID);
                    }
                }
            }

            // Search server for entry matching hostname
            if (nodeID == null && name != null && name != "")
            {
                request = WebRequest.Create(server + "nodes.xml?exact_node[name]=" + Uri.EscapeUriString(name));
                HttpWebResponse response = (HttpWebResponse)request.GetResponse();
                if (response.StatusCode == HttpStatusCode.OK)
                {
                    XPathDocument document = new XPathDocument(response.GetResponseStream());
                    XPathNavigator navigator = document.CreateNavigator();
                    XPathNavigator node = navigator.SelectSingleNode("/nodes/node/id");
                    if (node != null)
                    {
                        nodeID = node.Value;
                        Console.WriteLine("Node ID from name search: " + nodeID);
                    }
                }
            }

            // Authenticate to get cookie
            request = WebRequest.Create(Regex.Replace(server, "^http", "https") + "login/login");
            CookieContainer cookieContainer = new CookieContainer();
            ((HttpWebRequest)request).CookieContainer = cookieContainer;
            // There's no reason to chase the redirect we'll get in response
            ((HttpWebRequest)request).AllowAutoRedirect = false;
            request.Method = "POST";
            request.ContentType = "application/x-www-form-urlencoded";
            String username = "autoreg";
            String password = "qq8Erkee&T";
            String authBody = "login=" + Uri.EscapeDataString(username) + "&password=" + Uri.EscapeDataString(password);
            byte[] authBodyBytes = Encoding.UTF8.GetBytes(authBody);
            request.ContentLength = authBodyBytes.Length;
            using (Stream writeStream = request.GetRequestStream())
            {
                writeStream.Write(authBodyBytes, 0, authBodyBytes.Length);
            }
            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            {
                // If we were redirected to / then authentication was successful.
                // If we were redirected back to /login/login then authentication failed.
                if (response.StatusCode != HttpStatusCode.Found ||
                    (new Uri(response.Headers["Location"])).AbsolutePath == "/login/login")
                {
                    Console.WriteLine("Authentication failed");
                    Environment.Exit(1);
                }
                Console.WriteLine("Authentication successful");
                CookieCollection cookieCollection = cookieContainer.GetCookies(new Uri(server));
            }

            // Submit entry
            if (nodeID != null)
            {
                // There's an existing entry.  PUT to it to update.
                Console.WriteLine("Updating existing entry");
                request = WebRequest.Create(server + "nodes/" + nodeID + ".xml");
                request.Method = "PUT";
            }
            else
            {
                // There is no existing entry.  POST to make one.
                Console.WriteLine("Creating new entry");
                request = WebRequest.Create(server + "nodes.xml");
                request.Method = "POST";
            }
            ((HttpWebRequest)request).CookieContainer = cookieContainer;
            request.ContentType = "application/x-www-form-urlencoded";
            byte[] bodyBytes = Encoding.UTF8.GetBytes(body);
            request.ContentLength = bodyBytes.Length;
            using (Stream writeStream = request.GetRequestStream())
            {
                writeStream.Write(bodyBytes, 0, bodyBytes.Length);
            }
            // FIXME: This can go away after development.  We don't particularly care if it failed, nothing we can do about it.  Although logging an error would be nice.
            using (WebResponse response = request.GetResponse())
            {
                Console.WriteLine(((HttpWebResponse)response).StatusDescription);
                // Get the stream containing content returned by the server.
                using (Stream responseStream = response.GetResponseStream())
                {
                    using (StreamReader reader = new StreamReader(responseStream))
                    {
                        string responseFromServer = reader.ReadToEnd();
                        // Display the content.
                        Console.WriteLine(responseFromServer);
                    }
                }
            }

            Thread.Sleep(30000);
        }
    }
}
