# Complete Beginner's Guide: Setting a Static IP on Ubuntu for Android Hotspot

## What You Need to Know First

When your Ubuntu laptop connects to an Android hotspot, it normally gets an IP address automatically (called DHCP). A **static IP** means your laptop always uses the same IP address when connected to that hotspot.

---

## Step 1: Find Your Hotspot's IP Range

Before setting a static IP, you need to know what IP addresses your hotspot uses.

### 1.1 Connect to Your Android Hotspot
- Turn on the hotspot on your Android phone
- On Ubuntu, connect to it normally (just like connecting to any Wi-Fi)

### 1.2 Find the Gateway IP
Open a terminal (`Ctrl+Alt+T`) and type:

```bash
ip route | grep default
```

You'll see something like:
```
default via 192.168.43.1 dev wlan0
```

The important number is **192.168.43.1** - this is your **gateway IP** (your hotspot's address).

### 1.3 Understand the IP Range
Based on the gateway IP, here's what you can use:

| Gateway IP      | Your Static IP Range          | Example Static IP |
|----------------|-------------------------------|-------------------|
| 192.168.43.1   | 192.168.43.2 to 192.168.43.254 | 192.168.43.50    |
| 192.168.6.1    | 192.168.6.2 to 192.168.6.254   | 192.168.6.50     |
| 172.20.10.1    | 172.20.10.2 to 172.20.10.254   | 172.20.10.50     |
| 10.42.0.1      | 10.42.0.2 to 10.42.0.254       | 10.42.0.50       |

**Rule**: Keep the first three numbers the same as the gateway, only change the last number (between 2-254). Avoid using the gateway IP and avoid your current DHCP IP (from `src` in `ip route`).

---

## Step 2: Set Static IP Using GUI (Easiest Method)

### 2.1 Open Wi-Fi Settings
1. Click the **Wi-Fi icon** in the top-right corner
2. Click **Wi-Fi Settings** or **Settings**
3. Find your Android hotspot in the list

### 2.2 Edit the Connection
1. Click the **⚙️ gear icon** next to your hotspot name
2. Click the **IPv4** tab

### 2.3 Configure Static IP
1. Change **IPv4 Method** from `Automatic (DHCP)` to **`Manual`**
2. Click the **Add** button under "Addresses"
3. Fill in the fields:

   | Field      | What to Enter                          | Example          |
   |-----------|----------------------------------------|------------------|
   | Address   | Your chosen static IP (see table above) | 192.168.43.50    |
   | Netmask   | Type `255.255.255.0` OR just `24`      | 24               |
   | Gateway   | The gateway IP you found in Step 1.2   | 192.168.43.1     |

4. In the **DNS** field, enter: `8.8.8.8, 1.1.1.1`

### 2.4 Apply and Reconnect
1. Click **Apply**
2. Turn Wi-Fi **off** then back **on**
3. Reconnect to your hotspot

---

## Step 3: Verify It's Working

Open a terminal and check your IP:

```bash
IFACE=$(ip route | awk '/default/ {print $5; exit}')
ip addr show "$IFACE" | grep inet
```

You should see your static IP (e.g., `192.168.43.50`).

Test internet connection:
```bash
ping -c 4 8.8.8.8
```

If you see replies, it's working! ✅

---

## Troubleshooting

### Problem 1: "No Internet" After Setting Static IP

**Cause**: Wrong gateway or subnet.

**Fix**:
1. Reconnect to the hotspot normally (DHCP)
2. Check the gateway again:
   ```bash
   ip route | grep default
   ```
3. Update your static IP settings to match the correct subnet

---

### Problem 2: Hotspot IP Range Changed

Some Android phones (especially Android 11+) change the subnet randomly (e.g., from `192.168.43.x` to `192.168.6.x`).

**Symptoms**: Static IP stops working after you restart the hotspot.

**Quick Fix**:
1. Open Wi-Fi Settings → Click gear icon → IPv4 tab
2. Check the new gateway:
   ```bash
   ip route | grep default
   ```
3. Update the **Address** and **Gateway** to match the new subnet
4. Example: If gateway changed to `192.168.43.1`, set:
   - Address: `192.168.43.50`
   - Gateway: `192.168.43.1`

### Note: Samsung Galaxy S24 Ultra (Android 16)
On Samsung One UI, the hotspot subnet can change after toggling the hotspot, rebooting, or applying updates. If your static IP stops working, re-check the gateway with:
```bash
ip route | grep default
```
and update your static IP to match the new subnet.

--- 

### Problem 3: Can't Access the Internet But Connected

**Fix**: Check DNS settings.
1. Go back to IPv4 settings
2. Make sure DNS is set to `8.8.8.8, 1.1.1.1`
3. Apply and reconnect

---

## Alternative: Command Line Method

If you prefer using the terminal:

```bash
# 1. Find your connection name
nmcli con show

# 2. Set static IP (replace "YourHotspotName" with actual name)
nmcli con mod "YourHotspotName" ipv4.method manual \
  ipv4.addresses 192.168.43.50/24 \
  ipv4.gateway 192.168.43.1 \
  ipv4.dns "8.8.8.8,1.1.1.1"

# 3. Reconnect
nmcli con down "YourHotspotName"
nmcli con up "YourHotspotName"
```

---

## When Do You Need a Static IP?

You typically need a static IP if you're:
- Running a server on your laptop (web server, SSH, etc.)
- Port forwarding from the hotspot to your laptop
- Using specific software that requires a fixed IP

**If you don't need these**, using automatic DHCP is simpler and works fine!

---

## Quick Reference Card

```
Step 1: Find gateway
  Command: ip route | grep default
  Result: 192.168.43.1 (example)

Step 2: Choose static IP
  Use: 192.168.43.50 (example - same first 3 numbers)

Step 3: Set in GUI
  Settings → Wi-Fi → Gear Icon → IPv4 → Manual
  Address: 192.168.43.50
  Netmask: 24
  Gateway: 192.168.43.1
  DNS: 8.8.8.8, 1.1.1.1

Step 4: Apply and reconnect
```

---

## Need More Help?

If something isn't working:
1. Share the output of:
   ```bash
   ip route
   IFACE=$(ip route | awk '/default/ {print $5; exit}')
   ip addr show "$IFACE"
   ```
2. Share which Android phone model you're using

Good luck! 🚀
