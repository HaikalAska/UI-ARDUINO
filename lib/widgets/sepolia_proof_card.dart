import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/habitat_data.dart';
import 'tactile_card.dart';

/// Kartu tipis berlatar indigo pastel dengan ikon rantai terverifikasi (Sepolia)
/// Sesuai Kartu 4 Blueprint T.H.A.L.I.A
class SepoliaProofCard extends StatelessWidget {
  final BlockchainProof proof;

  const SepoliaProofCard({
    super.key,
    required this.proof,
  });

  void _showProofModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SepoliaProofDetailSheet(proof: proof),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      onTap: () => _showProofModal(context),
      backgroundColor: AppColors.blockchainIndigoBg,
      border: Border.all(
        color: AppColors.blockchainIndigoBorder,
        width: 1.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.blockchainIndigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_rounded,
              color: AppColors.blockchainIndigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Sepolia On-Chain',
                        style: TextStyle(
                          color: AppColors.blockchainIndigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.blockchainIndigo,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Flexible(
                      child: Text(
                        'Block #6,428,910',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Data Terkunci di Smart Contract Sepolia • Hash SHA-256 Valid',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.blockchainIndigo,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SepoliaProofDetailSheet extends StatelessWidget {
  final BlockchainProof proof;

  const _SepoliaProofDetailSheet({required this.proof});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blockchainIndigoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.blockchainIndigo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bukti Integritas On-Chain',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Verifikasi Kriptografis Smart Contract',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoRow(
              context,
              label: 'Jaringan Blockchain',
              value: proof.network,
              copyable: false,
            ),
            _infoRow(
              context,
              label: 'Status Verifikasi',
              value: 'LOCKED & VERIFIED (SHA-256 Valid)',
              isHighlight: true,
            ),
            _infoRow(
              context,
              label: 'Smart Contract Sepolia',
              value: proof.contractAddress,
              copyable: true,
            ),
            _infoRow(
              context,
              label: 'Transaction Hash',
              value: proof.transactionHash,
              copyable: true,
            ),
            _infoRow(
              context,
              label: 'Nomor Blok',
              value: '#${proof.blockNumber}',
              copyable: false,
            ),
            _infoRow(
              context,
              label: 'Waktu Timestamp',
              value: proof.timestamp,
              copyable: false,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _copy(context, proof.transactionHash, 'Transaction Hash');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Salin Bukti Transaksi SHA-256'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blockchainIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isHighlight
                        ? AppColors.statusSafeText
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight:
                        isHighlight ? FontWeight.w700 : FontWeight.w600,
                    fontFamily: copyable ? 'monospace' : null,
                  ),
                ),
              ),
              if (copyable)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copy(context, value, label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
