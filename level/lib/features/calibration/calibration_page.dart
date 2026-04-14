import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/calibration.dart';
import '../../state/sensor_provider.dart';

// Two-step calibration flow.
// Step 1: phone flat on surface  → capture
// Step 2: phone rotated 180° around Z → capture → save offset

enum _CalibStep { ready, step1Done, complete, failed }

class CalibrationPage extends ConsumerStatefulWidget {
  const CalibrationPage({super.key});

  @override
  ConsumerState<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends ConsumerState<CalibrationPage> {
  final _calib = TwoStepCalibration();
  _CalibStep _step = _CalibStep.ready;
  CalibrationData? _result;

  void _captureStep1() {
    final reading = ref.read(rawTiltProvider).value;
    if (reading == null) return;
    _calib.captureStep1(reading);
    setState(() => _step = _CalibStep.step1Done);
  }

  void _captureStep2() {
    final reading = ref.read(rawTiltProvider).value;
    if (reading == null) return;
    final result = _calib.captureStep2(reading);
    if (result == null) {
      setState(() => _step = _CalibStep.failed);
      return;
    }
    _result = result;
    ref.read(calibrationProvider.notifier).applyCalibration(result);
    setState(() => _step = _CalibStep.complete);
  }

  void _reset() {
    _calib.reset();
    setState(() {
      _step = _CalibStep.ready;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calibrate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: _step == _CalibStep.complete
              ? _buildComplete()
              : _step == _CalibStep.failed
                  ? _buildFailed()
                  : _buildSteps(),
        ),
      ),
    );
  }

  Widget _buildSteps() {
    final isStep2 = _step == _CalibStep.step1Done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(step: isStep2 ? 2 : 1, total: 2),
        const SizedBox(height: 32),
        _PhoneIllustration(rotated: isStep2),
        const SizedBox(height: 32),
        Text(
          isStep2 ? 'Step 2 of 2' : 'Step 1 of 2',
          style: AppTextStyles.sectionHeader(),
        ),
        const SizedBox(height: 8),
        Text(
          isStep2
              ? 'Now rotate the phone 180° end-for-end (like a steering wheel), keeping it on the same surface. This cancels any sensor bias.'
              : 'Rest your phone flat on the most level surface you have access to — a known-flat table or countertop. Hold it still.',
          style: AppTextStyles.label(
              fontSize: 15, color: AppColors.textSecondary),
        ),
        const Spacer(),
        _CalibButton(
          label: isStep2 ? 'CAPTURE STEP 2' : 'CAPTURE STEP 1',
          onTap: isStep2 ? _captureStep2 : _captureStep1,
        ),
        if (isStep2) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _reset,
              child: Text('Start over',
                  style: AppTextStyles.label(color: AppColors.textMuted)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComplete() {
    final offset = _result;
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.check_circle_outline,
            size: 72, color: AppColors.levelAchieved),
        const SizedBox(height: 24),
        Text(
          'Calibrated.',
          style: AppTextStyles.readout(fontSize: 32),
        ),
        if (offset != null) ...[
          const SizedBox(height: 8),
          Text(
            'Offset: X ${offset.xOffset.toStringAsFixed(3)}, '
            'Y ${offset.yOffset.toStringAsFixed(3)} m/s²  — nailed it.',
            style: AppTextStyles.label(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        _CalibButton(
          label: 'DONE',
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _reset,
            child: Text('Calibrate again',
                style: AppTextStyles.label(color: AppColors.textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      children: [
        const Spacer(),
        Text('Something went wrong.',
            style: AppTextStyles.readout(fontSize: 24)),
        const SizedBox(height: 16),
        Text(
          'Couldn\'t read the sensor. Make sure the phone is still and try again.',
          style: AppTextStyles.label(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        _CalibButton(label: 'TRY AGAIN', onTap: _reset),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final int total;
  const _StepIndicator({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < step;
        return Container(
          width: 24,
          height: 3,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.levelAchieved : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _PhoneIllustration extends StatelessWidget {
  final bool rotated;
  const _PhoneIllustration({required this.rotated});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedRotation(
        turns: rotated ? 0.5 : 0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Container(
          width: 80,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.levelAchieved.withAlpha(120),
                      width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.levelAchieved,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CalibButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.levelAchieved.withAlpha(150)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.sectionHeader().copyWith(
                color: AppColors.levelAchieved,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
