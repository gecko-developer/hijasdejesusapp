import 'package:flutter/material.dart';
import '../services/fcm_token_service.dart';
import '../services/nfc_service_new.dart';
import '../theme/app_theme.dart';

class RFIDLinkScreen extends StatefulWidget {
  const RFIDLinkScreen({super.key});

  @override
  State<RFIDLinkScreen> createState() => _RFIDLinkScreenState();
}

class _RFIDLinkScreenState extends State<RFIDLinkScreen> 
    with TickerProviderStateMixin {
  final _rfidController = TextEditingController();
  final FCMTokenService _tokenService = FCMTokenService();
  bool _isLoading = false;
  bool _isScanning = false;
  bool _nfcAvailable = false;
  String? _message;
  Color? _messageColor;

  late AnimationController _cardController;
  late AnimationController _scanController;
  late Animation<double> _cardAnimation;
  late Animation<Color?> _scanColorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNFC();
  }

  void _setupAnimations() {
    _cardController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scanController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _scanColorAnimation = ColorTween(
      begin: AppTheme.primaryBlue,
      end: AppTheme.successGreen,
    ).animate(_scanController);

    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _scanController.dispose();
    _rfidController.dispose();
    NFCService.dispose();
    super.dispose();
  }

  Future<void> _initializeNFC() async {
    final available = await NFCService.initialize();
    setState(() {
      _nfcAvailable = available;
    });
    
    if (!available) {
      _showMessage('⚠️ NFC is not available on this device', AppTheme.warningOrange);
    }
  }

  void _showMessage(String message, Color color) {
    setState(() {
      _message = message;
      _messageColor = color;
    });
    
    // Auto-clear message after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
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
      _showMessage('❌ NFC is not available', AppTheme.errorRed);
      return;
    }

    setState(() {
      _isScanning = true;
    });
    
    _scanController.repeat();
    _showMessage('📱 Hold your RFID card near the phone...', AppTheme.primaryBlue);

    try {
      final rfidCard = await NFCService.scanRFIDCard();
      
      if (rfidCard != null) {
        setState(() {
          _rfidController.text = rfidCard;
        });
        _showMessage('✅ RFID card scanned: $rfidCard', AppTheme.successGreen);
        _scanController.forward();
      } else {
        _showMessage('❌ Could not read RFID card', AppTheme.errorRed);
        _scanController.reset();
      }
    } catch (e) {
      _showMessage('❌ Scanning failed: ${e.toString()}', AppTheme.errorRed);
      _scanController.reset();
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  String _formatUID(String input) {
    String formatted = input.trim().toUpperCase();
    formatted = formatted.replaceAll(':', '');
    formatted = formatted.replaceAll(' ', '');
    formatted = formatted.replaceAll('-', '');
    
    if (!formatted.startsWith('CARD_')) {
      formatted = 'CARD_$formatted';
    }
    
    return formatted;
  }

  Future<void> _linkRFIDCard() async {
    if (_rfidController.text.trim().isEmpty) {
      _showMessage('Please enter an RFID card ID', AppTheme.errorRed);
      return;
    }

    final rfidRegex = RegExp(r'^CARD_[A-F0-9]+$');
    if (!rfidRegex.hasMatch(_rfidController.text.trim())) {
      _showMessage('Invalid RFID format. Should be CARD_XXXXXXXX (hex characters only)', AppTheme.errorRed);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _tokenService.linkRFIDCard(_rfidController.text.trim());
      _showMessage('✅ RFID card linked successfully!', AppTheme.successGreen);
      setState(() {
        _rfidController.clear();
      });
    } catch (e) {
      _showMessage('❌ Error linking RFID card: $e', AppTheme.errorRed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: CustomScrollView(
          slivers: [
            // 🎨 Modern App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: AppTheme.radiusSmall,
                    boxShadow: AppTheme.shadowSmall,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.darkGrey,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Link RFID Card',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.darkGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            
            // 📱 Main Content
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimation.value,
                    child: Opacity(
                      opacity: _cardAnimation.value,
                      child: _buildMainContent(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        children: [
          // 🎯 Hero Section
          _buildHeroSection(),
          
          SizedBox(height: AppTheme.spacing32),
          
          // 📱 NFC Scanner Section
          if (_nfcAvailable) ...[
            _buildNFCSection(),
            SizedBox(height: AppTheme.spacing24),
            _buildDivider(),
            SizedBox(height: AppTheme.spacing24),
          ],
          
          // ⌨️ Manual Input Section
          _buildInputSection(),
          
          SizedBox(height: AppTheme.spacing24),
          
          // 🔗 Link Button
          _buildLinkButton(),
          
          SizedBox(height: AppTheme.spacing24),
          
          // 💬 Message Display
          if (_message != null) _buildMessageCard(),
          
          SizedBox(height: AppTheme.spacing24),
          
          // 📚 Help Section
          _buildHelpSection(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: AppTheme.radiusLarge,
        ),
        padding: EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _nfcAvailable ? Icons.nfc : Icons.credit_card,
                size: 64,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: AppTheme.spacing20),
            
            Text(
              'Connect Your RFID Card',
              style: AppTheme.headingLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppTheme.spacing12),
            
            Text(
              _nfcAvailable 
                  ? 'Tap your RFID card to scan instantly or enter manually'
                  : 'Enter your RFID card UID to link it to your account',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFCSection() {
    return AnimatedCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: AppTheme.radiusMedium,
                ),
                child: Icon(
                  Icons.nfc,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC Scanner',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tap to scan your RFID card instantly',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacing20),
          
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              if (_isScanning) {
                return Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _scanColorAnimation.value ?? AppTheme.primaryBlue,
                        AppTheme.successGreen,
                      ],
                    ),
                    borderRadius: AppTheme.radiusMedium,
                    boxShadow: AppTheme.shadowMedium,
                  ),
                  child: MaterialButton(
                    onPressed: null,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.radiusMedium,
                    ),
                    child: Row(
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
                        SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Hold card near phone...',
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return GradientButton(
                  text: 'Tap RFID Card',
                  icon: Icons.nfc,
                  gradient: AppTheme.successGradient,
                  onPressed: _isLoading ? null : _scanNFCCard,
                  width: double.infinity,
                  height: 56,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.lightGrey, Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Text(
            'OR',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.mediumGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.lightGrey, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.radiusMedium,
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Entry',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Enter your RFID card UID in any format',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacing20),
          
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: AppTheme.radiusMedium,
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _rfidController,
              decoration: InputDecoration(
                labelText: 'RFID Card UID',
                labelStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGrey),
                hintText: 'F6:92:D6:05 or F692D605',
                hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGrey),
                prefixIcon: Icon(Icons.credit_card, color: AppTheme.primaryBlue),
                suffixIcon: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(AppTheme.spacing4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: AppTheme.radiusSmall,
                    ),
                    child: Icon(
                      Icons.auto_fix_high,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    if (_rfidController.text.isNotEmpty) {
                      String formatted = _formatUID(_rfidController.text);
                      setState(() {
                        _rfidController.text = formatted;
                      });
                    }
                  },
                  tooltip: 'Auto-format UID',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing16,
                ),
                helperText: 'Will be formatted as CARD_XXXXXXXX',
                helperStyle: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGrey),
              ),
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.darkGrey,
                fontWeight: FontWeight.w500,
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: !_isLoading && !_isScanning,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton() {
    if (_isLoading) {
      return Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: AppTheme.radiusMedium,
          boxShadow: AppTheme.shadowMedium,
        ),
        child: MaterialButton(
          onPressed: null,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusMedium,
          ),
          child: Row(
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
              SizedBox(width: AppTheme.spacing12),
              Text(
                'Linking to Firestore...',
                style: AppTheme.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return GradientButton(
        text: 'Link RFID Card',
        icon: Icons.link,
        gradient: AppTheme.primaryGradient,
        onPressed: _isScanning ? null : _linkRFIDCard,
        width: double.infinity,
        height: 56,
      );
    }
  }

  Widget _buildMessageCard() {
    return AnimatedCard(
      color: _messageColor?.withOpacity(0.1) ?? AppTheme.lightGrey,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _messageColor?.withOpacity(0.3) ?? AppTheme.lightGrey,
            width: 1,
          ),
          borderRadius: AppTheme.radiusMedium,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: _messageColor?.withOpacity(0.2) ?? AppTheme.lightGrey,
                borderRadius: AppTheme.radiusMedium,
              ),
              child: Icon(
                _messageColor == AppTheme.successGreen 
                    ? Icons.check_circle 
                    : _messageColor == AppTheme.errorRed 
                        ? Icons.error 
                        : Icons.info,
                color: _messageColor ?? AppTheme.mediumGrey,
                size: 24,
              ),
            ),
            SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Text(
                _message!,
                style: AppTheme.bodyMedium.copyWith(
                  color: _messageColor ?? AppTheme.mediumGrey,
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
    return Column(
      children: [
        // Examples Card
        AnimatedCard(
          color: AppTheme.backgroundGrey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Format Examples',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.darkGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing12),
              _buildExampleRow('F6:92:D6:05', 'CARD_F692D605'),
              _buildExampleRow('A1-B2-C3-D4', 'CARD_A1B2C3D4'),
              _buildExampleRow('12345678', 'CARD_12345678'),
            ],
          ),
        ),
        
        SizedBox(height: AppTheme.spacing16),
        
        // Info Card
        AnimatedCard(
          color: AppTheme.primaryBlue.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: AppTheme.radiusMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: AppTheme.spacing8),
                    Text(
                      'How it works',
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing12),
                Text(
                  _nfcAvailable
                      ? '• Tap the green NFC button and hold your card near the phone\n'
                        '• Or enter the UID manually in any format\n'
                        '• Your card will be securely linked to your account\n'
                        '• Notifications will appear when your card is scanned'
                      : '• Enter your RFID card UID in any format\n'
                        '• Use the magic wand button to auto-format\n'
                        '• Your card will be securely linked to your account\n'
                        '• Notifications will appear when your card is scanned',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleRow(String input, String output) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              input,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.mediumGrey,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 14,
            color: AppTheme.mediumGrey,
          ),
          SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              output,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.darkGrey,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
