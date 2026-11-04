# 00GHLCopy Follower Script

This script monitors and follows all trading events from the original 00GHLCopy Expert Advisor.

## What It Does

The Follower Script will:
- ✅ **Monitor** all trades opened by the original 00GHLCopy EA
- ✅ **Copy** new trades to your account (if enabled)
- ✅ **Close** copied trades when the original closes (if enabled)
- ✅ **Log** all trading events for analysis
- ✅ **Send notifications** for new trades and closures

## Installation

1. Download `00GHLCopy_Follower.mq4` from the GitHub repository
2. Copy to your MT4 `MQL4/Scripts` folder (NOT Experts folder)
3. Open MetaEditor (F4)
4. Compile the script (F7)
5. The compiled `.ex4` file will appear in Scripts folder

## How to Use

### Step 1: Run the Original EA
- First, attach the original `00GHLCopy.ex4` to a chart
- Let it open trades normally

### Step 2: Run the Follower Script
- Navigate to "Scripts" in MT4 Navigator
- Find `00GHLCopy_Follower`
- Drag and drop it onto the same chart (or any chart)
- Configure parameters in the dialog box
- Click OK

### Step 3: Monitor
- The script will run in the background
- Check the "Experts" tab in MT4 for logs
- Logs are also saved to `MQL4/Files/GHL_Follower.log`

## Configuration Parameters

### Trade Copying Settings
- **CopyTrades**: Enable/disable trade copying (default: true)
- **CloseOnOriginalClose**: Close copies when original closes (default: true)
- **CopyLotMultiplier**: Multiply lot size (1.0 = same lot, 0.5 = half lot, 2.0 = double)
- **Slippage**: Maximum allowed slippage in points (default: 3)
- **MagicNumber**: Unique ID for copied trades (default: 54321)

### Logging Settings
- **EnableLogging**: Enable logging to Experts tab (default: true)
- **LogToFile**: Save logs to file (default: true)
- **LogFileName**: Name of log file (default: GHL_Follower.log)

### Filter Settings
- **FollowSymbol**: Only copy trades for this symbol (empty = all symbols)
- **FollowOnlyNewTrades**: Only copy trades opened after script starts (default: false)

### Notification Settings
- **EnableAlerts**: Show popup alerts (default: true)
- **EnableEmail**: Send email notifications (requires email setup in MT4)
- **EnablePush**: Send push notifications to mobile app

## Important Notes

### Magic Number
The script assumes the original EA uses magic number `123456`. If your original EA uses a different magic number, you need to:
1. Open `00GHLCopy_Follower.mq4` in MetaEditor
2. Find line: `int g_originalMagicNumber = 123456;`
3. Change `123456` to your EA's magic number
4. Recompile

### How to Find Original EA's Magic Number
- Right-click on a trade opened by the original EA
- Select "Order" or "Properties"
- Look for "Magic" or "Expert ID" field
- Use that number in the script

### Script vs Expert Advisor
- This is a **Script**, not an EA
- Scripts run once and stop (unless programmed to loop)
- This script runs in a continuous loop to monitor trades
- It will stop when:
  - You remove it from the chart
  - You close MT4
  - You click "Stop" in the script dialog

### Same Account vs Different Account
**Same Account** (default behavior):
- Both EA and script run on same MT4 instance
- Script monitors and copies trades within same account
- Useful for logging/analysis

**Different Account** (requires modification):
- If you want to copy to a different account/broker
- Need to use trade copier EA (not this script)
- Or modify this script to use trade copy signals

## Use Cases

### 1. Trade Analysis
- Set `CopyTrades = false`
- Script will log all trades without copying
- Analyze the EA's performance and patterns

### 2. Risk Management
- Set `CopyLotMultiplier = 0.5` (half size)
- Copy trades at reduced risk
- Test EA with smaller positions

### 3. Multiple Timeframes
- Run original EA on one timeframe
- Run follower script on different charts
- Monitor all activity from one place

### 4. Backup Monitoring
- Run script on second computer
- Monitor trades remotely
- Get notifications on mobile

## Log File Location

The log file is saved to:
```
MT4 Data Folder → MQL4 → Files → GHL_Follower.log
```

Typical location:
```
C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\[RandomID]\MQL4\Files\GHL_Follower.log
```

## Troubleshooting

### Script not copying trades
- Check if original EA is actually opening trades
- Verify magic number matches
- Check "Experts" tab for error messages
- Ensure `CopyTrades = true`

### Script stops immediately
- Check if MT4 has trading disabled
- Verify script compiled successfully
- Check log file for errors

### Duplicate trades
- Script checks for existing copies before copying
- If you see duplicates, magic number might be wrong
- Or script was restarted while trades were open

### No notifications
- Enable `EnableAlerts = true`
- For email: configure email in MT4 Tools → Options → Email
- For push: enable MetaQuotes ID in MT4

## Example Output

```
[2026.11.04 01:30:00] ========================================
[2026.11.04 01:30:00] GHL Follower Script Started
[2026.11.04 01:30:00] ========================================
[2026.11.04 01:30:00] Start Time: 2026.11.04 01:30:00
[2026.11.04 01:30:00] Copy Trades: true
[2026.11.04 01:30:00] ========================================
[2026.11.04 01:30:05] Scanning for existing trades from original EA...
[2026.11.04 01:30:05] Total existing trades found: 0
[2026.11.04 01:35:15] NEW TRADE DETECTED: BUY EURUSD Lot: 0.10 Price: 1.0850 Ticket: 123456
[2026.11.04 01:35:15] TRADE COPIED SUCCESSFULLY: Original #123456 -> New #789012 EURUSD BUY Lot: 0.10
[2026.11.04 01:40:20] ORIGINAL TRADE CLOSED: Ticket 123456
[2026.11.04 01:40:20] CLOSED COPY: Ticket #789012 (Original #123456)
```

## Advanced Usage

### Custom Magic Number
If you have multiple EAs running, you can:
1. Modify the script to track multiple magic numbers
2. Create separate follower scripts for each EA
3. Use different magic numbers for copied trades

### Trade Modification
The script currently:
- Opens trades at current market price
- Uses same SL/TP as original
- Does not modify open trades

You can extend it to:
- Track SL/TP changes
- Modify copied trades when original changes
- Add trailing stop logic

## Safety Notes

⚠️ **Important Warnings**:
- Always test on demo account first
- Start with small lot sizes
- Monitor trades closely
- Script relies on correct magic number
- No guarantee of exact trade replication
- Network delays can cause slippage
- Different brokers may have different prices

## Support

For issues or customization:
- Check the log file for errors
- Verify magic number is correct
- Ensure both EA and script are running
- Review MT4 Experts tab for messages

---

**Generated by Devin AI Assistant**
Trade Follower Script for 00GHLCopy EA
