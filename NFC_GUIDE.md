# NFC RFID Card Linking Guide

## 📱 **How to Use NFC Scanning**

### **For Users:**

1. **Open the RFID Link Screen**
   - Tap the credit card icon in the app bar
   - You'll see the "Link Your RFID Card" screen

2. **Choose Your Method**
   - **NFC Scanning**: Tap the green "Scan NFC Card" button
   - **Manual Entry**: Type or paste the RFID UID

3. **NFC Scanning Process**
   - Tap "Scan NFC Card" button
   - Hold your RFID card against the back of your phone
   - Wait for the vibration/sound confirmation
   - The UID will automatically appear in the text field
   - Formatted as "CARD_XXXXXXXX"

4. **Complete the Linking**
   - Review the formatted RFID ID
   - Tap "Link RFID Card"
   - Success! Your card is now linked

### **Supported RFID Card Types:**
- **ISO 14443 Type A** (most common RFID cards)
- **ISO 14443 Type B** 
- **ISO 15693** (vicinity cards)
- **FeliCa** (common in Japan)

### **Card Examples:**
- Office access cards
- Hotel key cards  
- Public transport cards
- Student ID cards
- Gym membership cards
- Library cards

### **Troubleshooting NFC:**

**"NFC not available"**
- Check if your phone has NFC capability
- Enable NFC in phone settings
- Try restarting the app

**"Could not read card"**
- Hold the card closer to the phone
- Try different positions on the back of phone
- Remove phone case if thick
- Ensure the card is an RFID/NFC card

**"Scanning failed"**
- Make sure NFC is enabled in system settings
- Check if another NFC app is running
- Restart the NFC scanning process

### **Manual Entry Fallback:**

If NFC doesn't work, you can manually enter the UID:

**Formats Accepted:**
- `F6:92:D6:05` (with colons)
- `F6-92-D6-05` (with dashes)  
- `F6 92 D6 05` (with spaces)
- `F692D605` (no separators)

**Auto-formatting:**
- All formats convert to `CARD_F692D605`
- Tap the magic wand icon for instant formatting
- Input is automatically converted to uppercase

### **Finding Your Card's UID:**

**Method 1: Using NFC Tools app**
1. Download "NFC Tools" from Play Store
2. Tap "Read" tab
3. Hold card to phone
4. Copy the UID from the results

**Method 2: Check the card**
- Some cards have the UID printed on them
- Look for numbers like "F6:92:D6:05"
- Usually on the back or embedded in text

**Method 3: Use a dedicated RFID reader**
- 125kHz or 13.56MHz RFID readers
- Copy the hex UID value

### **Security Notes:**
- UIDs are unique identifiers, not sensitive data
- Linking only associates the UID with your account
- No payment or personal info is stored
- You can unlink cards anytime

### **Success Flow:**
1. NFC scan or manual entry ✓
2. Auto-format to CARD_XXXXXXXX ✓  
3. Link to your account ✓
4. Receive notifications when scanned ✓

Your RFID card is now ready for notification alerts! 🎉
