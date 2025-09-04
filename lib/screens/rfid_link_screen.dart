import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fcm_token_service.dart';
import '../services/rfid_service.dart';
import '../services/nfc_service_new.dart';
import '../theme/app_theme.dart';

class RFIDLinkScreen extends StatefulWidget {
  const RFIDLinkScreen({super.key});

  @override
  State<RFIDLinkScreen> createState() => _RFIDLinkScreenState();
}

class _RFIDLinkScreenState extends State<RFIDLinkScreen> with WidgetsBindingObserver {
  final _rfidController = TextEditingController();
  final FCMTokenService _tokenService = FCMTokenService();
  final RFIDService _rfidService = RFIDService();
  bool _isLoading = false;
  bool _isScanning = false;
  bool _nfcAvailable = false;
  String? _message;
  Color? _messageColor;
  RFIDCard? _currentCard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNFC();
    _loadCurrentCard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rfidController.dispose();
    NFCService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Auto-check NFC status when app is resumed (user returns from settings)
      _refreshNFCStatus();
    }
  }

  Future<void> _initializeNFC() async {
    final available = await NFCService.initialize();
    setState(() {
      _nfcAvailable = available;
    });
  }

  Future<void> _openNFCSettings() async {
    try {
      // Try to open NFC settings on Android
      await const MethodChannel('nfc_settings').invokeMethod('openNFCSettings');
      
      // Show message after opening settings
      _showMessage('Please enable NFC and return to the app', AppTheme.primary500);
      
      // Auto-refresh after a delay to check if NFC was enabled
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _refreshNFCStatus();
        }
      });
    } catch (e) {
      print('Could not open NFC settings: $e');
      // Fallback: Show manual instructions
      _showNFCInstructions();
    }
  }

  void _showNFCInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.nfc, color: AppTheme.primary500),
            SizedBox(width: 8),
            Text('Enable NFC'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To scan RFID cards, please enable NFC:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            _buildInstructionStep('1', 'Open your device Settings'),
            _buildInstructionStep('2', 'Go to "Connected devices" or "Connections"'),
            _buildInstructionStep('3', 'Find and tap "NFC"'),
            _buildInstructionStep('4', 'Turn on NFC'),
            _buildInstructionStep('5', 'Return to this app'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.primary500, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NFC must be enabled to scan RFID cards',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primary700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openNFCSettings();
            },
            icon: Icon(Icons.settings),
            label: Text('Open Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warning500,
              side: BorderSide(color: AppTheme.warning500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshNFCStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary500,
              foregroundColor: Colors.white,
            ),
            child: Text('I\'ve Enabled NFC'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary500,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNFCStatus() async {
    final available = await NFCService.initialize();
    setState(() {
      _nfcAvailable = available;
    });
    
    if (available) {
      _showMessage('NFC is now enabled! You can scan RFID cards.', AppTheme.success500);
    } else {
      _showMessage('NFC is still disabled. Please enable it in Settings.', AppTheme.warning500);
    }
  }

  Future<void> _loadCurrentCard() async {
    try {
      final card = await _rfidService.getCurrentUserRFIDCard();
      setState(() {
        _currentCard = card;
      });
    } catch (e) {
      print('Error loading current card: $e');
    }
  }

  void _showMessage(String message, Color color) {
    setState(() {
      _message = message;
      _messageColor = color;
    });
    
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = null;
          _messageColor = null;
        });
      }
    });
  }

  Future<void> _scanNFCCard() async {
    if (!_nfcAvailable) {
      _showMessage('NFC is not available', AppTheme.error500);
      return;
    }

    setState(() {
      _isScanning = true;
    });
    
    _showMessage('Hold your RFID card near the phone...', AppTheme.primary500);

    try {
      final rfidCard = await NFCService.scanRFIDCard();
      
      if (rfidCard != null) {
        setState(() {
          _rfidController.text = rfidCard;
        });
        _showMessage('Card scanned: $rfidCard', AppTheme.success500);
      } else {
        _showMessage('Could not read card', AppTheme.error500);
      }
    } catch (e) {
      _showMessage('Scanning failed: ${e.toString()}', AppTheme.error500);
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  String _formatUID(String input) {
    String formatted = input.trim().toUpperCase();
    formatted = formatted.replaceAll(RegExp(r'[^A-F0-9]'), '');
    
    if (!formatted.startsWith('CARD_')) {
      formatted = 'CARD_$formatted';
    }
    
    return formatted;
  }

  Future<void> _linkRFIDCard() async {
    if (_rfidController.text.trim().isEmpty) {
      _showMessage('Please enter an RFID card ID', AppTheme.error500);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentCard != null) {
        // Update existing card
        await _rfidService.updateRFIDCard(_rfidController.text.trim());
        _showMessage('RFID card updated successfully!', AppTheme.success500);
      } else {
        // Link new card
        await _tokenService.linkRFIDCard(_rfidController.text.trim());
        _showMessage('RFID card linked successfully!', AppTheme.success500);
      }
      
      setState(() {
        _rfidController.clear();
      });
      
      // Reload current card info
      await _loadCurrentCard();
    } catch (e) {
      _showMessage('Error: $e', AppTheme.error500);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkRFIDCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlink RFID Card'),
        content: Text('Are you sure you want to unlink your RFID card? You won\'t receive notifications when it\'s scanned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error500),
            child: Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _rfidService.unlinkCurrentUserRFIDCard();
      _showMessage('RFID card unlinked successfully!', AppTheme.success500);
      await _loadCurrentCard();
    } catch (e) {
      _showMessage('Error unlinking card: $e', AppTheme.error500);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentCard != null ? 'Manage RFID Card' : 'Link RFID Card',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Card Status
            if (_currentCard != null)
              _buildCurrentCardSection(),
            
            if (_currentCard != null)
              SizedBox(height: AppTheme.space24),
            
            // Header Card
            _buildHeaderCard(),
            
            SizedBox(height: AppTheme.space24),
            
            // NFC Scanner Section
            if (_nfcAvailable) ...[
              _buildNFCScannerSection(),
              
              SizedBox(height: AppTheme.space20),
              
              if (_currentCard == null) ...[
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.space16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppTheme.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                
                SizedBox(height: AppTheme.space20),
              ],
            ] else ...[
              // NFC Not Available Section
              _buildNFCDisabledSection(),
              
              SizedBox(height: AppTheme.space20),
            ],
            
            // Manual Input Section
            _buildManualInputSection(),
            
            SizedBox(height: AppTheme.space20),
            
            // Message
            if (_message != null)
              _buildMessageCard(),
            
            if (_message != null) SizedBox(height: AppTheme.space20),
            
            // Help Section
            if (_currentCard == null)
              _buildHelpSection(),
            
            SizedBox(height: AppTheme.space40), // Extra bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCardSection() {
    if (_currentCard == null) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success50,
            AppTheme.success50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success500.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.success700,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RFID Card Linked',
                        style: AppTheme.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutral900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.space16),
            
            // Card ID display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neutral200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card ID',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutral500,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentCard!.rfidId,
                          style: AppTheme.bodyLarge.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutral800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _currentCard!.rfidId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Card ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                              backgroundColor: AppTheme.success500,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Linked on ${_currentCard!.linkedAt.toLocal().toString().split(' ')[0]}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppTheme.space16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _unlinkRFIDCard,
                    icon: Icon(Icons.link_off, size: 18),
                    label: Text(
                      'Unlink Card',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error500,
                      side: BorderSide(color: AppTheme.error500),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      _rfidController.text = _currentCard!.rfidId;
                    },
                    icon: Icon(Icons.edit, size: 18),
                    label: Text(
                      'Replace Card',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning500,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            Icon(
              _currentCard != null 
                  ? Icons.credit_card 
                  : (_nfcAvailable ? Icons.nfc : Icons.credit_card),
              size: 48,
              color: _currentCard != null ? AppTheme.success500 : AppTheme.primary500,
            ),
            SizedBox(height: AppTheme.space16),
            Text(
              _currentCard != null 
                  ? 'Manage Your RFID Card'
                  : 'Connect Your RFID Card',
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.space8),
            Text(
              _currentCard != null
                  ? 'Update or replace your linked RFID card'
                  : 'Each user can only have one RFID card linked at a time',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFCScannerSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success50,
            AppTheme.success50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success500.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.nfc,
                    color: AppTheme.success700,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFC Scanner',
                        style: AppTheme.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutral900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'READY',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.space16),
            
            // Description
            Text(
              _currentCard != null
                  ? 'Scan a new card to replace your current one'
                  : 'Hold your RFID card near the device to scan automatically',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutral600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppTheme.space20),
            
            // Scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _isScanning ? null : _scanNFCCard,
                icon: _isScanning 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.nfc, size: 20),
                label: Text(
                  _isScanning ? 'Scanning...' : 'Scan RFID Card',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: AppTheme.success500.withOpacity(0.3),
                ),
              ),
            ),
            
            if (_isScanning) ...[
              SizedBox(height: AppTheme.space16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primary200.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary600),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hold your RFID card near the device...',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primary700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNFCDisabledSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warning50,
            AppTheme.warning50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning500.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.nfc_outlined,
                    color: AppTheme.warning700,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFC Scanner',
                        style: AppTheme.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutral900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warning700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'DISABLED',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.space16),
            
            // Description
            Text(
              'Enable NFC to automatically scan RFID cards by holding them near your device.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutral600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppTheme.space20),
            
            // Action buttons - cleaner layout
            Column(
              children: [
                // Primary action - Open Settings
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openNFCSettings,
                    icon: Icon(Icons.settings_outlined, size: 20),
                    label: Text(
                      'Open NFC Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning500,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppTheme.warning500.withOpacity(0.3),
                    ),
                  ),
                ),
                
                SizedBox(height: AppTheme.space12),
                
                // Secondary actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showNFCInstructions,
                        icon: Icon(Icons.help_outline, size: 18),
                        label: Text('Help'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning700,
                          side: BorderSide(
                            color: AppTheme.warning500.withOpacity(0.3),
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _refreshNFCStatus,
                        icon: Icon(Icons.refresh, size: 18),
                        label: Text('Check'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.success700,
                          side: BorderSide(
                            color: AppTheme.success500.withOpacity(0.3),
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.space16),
            
            // Info note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary200.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primary600,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can still link cards manually using the form below',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primary700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: AppTheme.primary500),
                SizedBox(width: AppTheme.space8),
                Text(
                  _currentCard != null ? 'Replace Card' : 'Manual Entry',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space12),
            Text(
              _currentCard != null
                  ? 'Enter a new RFID card ID to replace your current one'
                  : 'Enter your RFID card ID in any format',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
            SizedBox(height: AppTheme.space16),
            TextField(
              controller: _rfidController,
              decoration: InputDecoration(
                labelText: _currentCard != null ? 'New RFID Card ID' : 'RFID Card ID',
                hintText: 'F6:92:D6:05 or F692D605',
                prefixIcon: Icon(Icons.credit_card),
                suffixIcon: IconButton(
                  icon: Icon(Icons.auto_fix_high),
                  onPressed: () {
                    if (_rfidController.text.isNotEmpty) {
                      String formatted = _formatUID(_rfidController.text);
                      setState(() {
                        _rfidController.text = formatted;
                      });
                    }
                  },
                  tooltip: 'Auto Format',
                ),
                border: OutlineInputBorder(
                  borderRadius: AppTheme.radius8,
                ),
                helperText: 'Will be formatted as CARD_XXXXXXXX',
              ),
              enabled: !_isLoading && !_isScanning,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                if (value.isNotEmpty && !value.startsWith('CARD_')) {
                  final formatted = _formatUID(value);
                  if (formatted != value) {
                    setState(() {
                      _rfidController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    });
                  }
                }
              },
            ),
            SizedBox(height: AppTheme.space20),
            ElevatedButton(
              onPressed: _isLoading || _isScanning ? null : _linkRFIDCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentCard != null ? AppTheme.warning500 : AppTheme.primary500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radius8,
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: AppTheme.space12),
                        Text(_currentCard != null ? 'Replacing...' : 'Linking...'),
                      ],
                    )
                  : Text(_currentCard != null ? 'Replace RFID Card' : 'Link RFID Card'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    if (_message == null) return SizedBox.shrink();
    
    return Card(
      elevation: 1,
      color: _messageColor?.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            Icon(
              _messageColor == AppTheme.success500 
                  ? Icons.check_circle 
                  : _messageColor == AppTheme.error500 
                      ? Icons.error 
                      : Icons.info,
              color: _messageColor,
            ),
            SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                _message!,
                style: TextStyle(
                  color: _messageColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      elevation: 1,
      color: AppTheme.neutral50,
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.neutral600),
                SizedBox(width: AppTheme.space8),
                Text(
                  'Important Information',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space16),
            _buildInfoRow(Icons.person, 'One card per user limit'),
            _buildInfoRow(Icons.security, 'Secure card-to-user linking'),
            _buildInfoRow(Icons.notifications, 'Instant scan notifications'),
            SizedBox(height: AppTheme.space16),
            Text(
              'Format Examples:',
              style: AppTheme.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.neutral700,
              ),
            ),
            SizedBox(height: AppTheme.space8),
            _buildExampleRow('F6:92:D6:05', 'CARD_F692D605'),
            _buildExampleRow('A1-B2-C3-D4', 'CARD_A1B2C3D4'),
            _buildExampleRow('12345678', 'CARD_12345678'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primary500,
          ),
          SizedBox(width: AppTheme.space8),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleRow(String input, String output) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              input,
              style: AppTheme.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: AppTheme.neutral600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: AppTheme.neutral500,
          ),
          SizedBox(width: AppTheme.space8),
          Expanded(
            flex: 2,
            child: Text(
              output,
              style: AppTheme.bodySmall.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppTheme.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
