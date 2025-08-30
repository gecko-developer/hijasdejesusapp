import 'package:flutter/material.dart';
import '../services/fcm_token_service.dart';
import '../services/rfid_service.dart';
import '../services/nfc_service_new.dart';
import '../theme/app_theme.dart';

class RFIDLinkScreen extends StatefulWidget {
  const RFIDLinkScreen({super.key});

  @override
  State<RFIDLinkScreen> createState() => _RFIDLinkScreenState();
}

class _RFIDLinkScreenState extends State<RFIDLinkScreen> {
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
    _initializeNFC();
    _loadCurrentCard();
  }

  @override
  void dispose() {
    _rfidController.dispose();
    NFCService.dispose();
    super.dispose();
  }

  Future<void> _initializeNFC() async {
    final available = await NFCService.initialize();
    setState(() {
      _nfcAvailable = available;
    });
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
            
            // NFC Scanner Section (if available and no card linked)
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
    
    return Card(
      elevation: 2,
      color: AppTheme.success50,
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.success500,
                  size: 32,
                ),
                SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RFID Card Linked',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.success700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppTheme.space4),
                      Text(
                        _currentCard!.rfidId,
                        style: AppTheme.bodyLarge.copyWith(
                          fontFamily: 'monospace',
                          color: AppTheme.success500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.space4),
                      Text(
                        'Linked on ${_currentCard!.linkedAt.toLocal().toString().split(' ')[0]}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.success500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _unlinkRFIDCard,
                    icon: Icon(Icons.link_off),
                    label: Text('Unlink Card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error500,
                      side: BorderSide(color: AppTheme.error500),
                      padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.space12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      _rfidController.text = _currentCard!.rfidId;
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Replace Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning500,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
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
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.nfc, color: AppTheme.success500),
                SizedBox(width: AppTheme.space8),
                Text(
                  'NFC Scanner',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space12),
            Text(
              _currentCard != null
                  ? 'Scan a new card to replace your current one'
                  : 'Hold your RFID card near the phone to scan',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
            SizedBox(height: AppTheme.space16),
            ElevatedButton.icon(
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
                  : Icon(Icons.nfc),
              label: Text(_isScanning ? 'Scanning...' : 'Scan RFID Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radius8,
                ),
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
