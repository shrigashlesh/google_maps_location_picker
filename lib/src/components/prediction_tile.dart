import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_location_picker/google_maps_location_picker.dart';

class PredictionTile extends StatelessWidget {
  final Prediction prediction;
  final ValueChanged<Prediction>? onTap;
  final PredictionTileTheme? predictionTileTheme;
  PredictionTile({
    required this.prediction,
    this.onTap,
    this.predictionTileTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: predictionTileTheme?.leading ?? Icon(Icons.location_on),
      title: RichText(
        text: TextSpan(
          children: _buildPredictionText(context),
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap!(prediction);
        }
      },
    );
  }

  List<TextSpan> _buildPredictionText(BuildContext context) {
    final List<TextSpan> result = <TextSpan>[];
    final textColor = Theme.of(context).textTheme.bodyMedium!.color;
    final regularStyle = predictionTileTheme?.regularStyle ??
        TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w300,
        );
    final matchedStyle = predictionTileTheme?.matchedStyle ??
        TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );
    if (prediction.matchedSubstrings.length > 0) {
      MatchedSubstring matchedSubString = prediction.matchedSubstrings[0];
      // There is no matched string at the beginning.
      if (matchedSubString.offset > 0) {
        result.add(
          TextSpan(
            text: prediction.description
                ?.substring(0, matchedSubString.offset as int?),
            style: regularStyle,
          ),
        );
      }

      // Matched strings.
      result.add(
        TextSpan(
          text: prediction.description?.substring(
              matchedSubString.offset as int,
              matchedSubString.offset + matchedSubString.length as int?),
          style: matchedStyle,
        ),
      );

      // Other strings.
      if (matchedSubString.offset + matchedSubString.length <
          (prediction.description?.length ?? 0)) {
        result.add(
          TextSpan(
            text: prediction.description?.substring(
                matchedSubString.offset + matchedSubString.length as int),
            style: regularStyle,
          ),
        );
      }
      // If there is no matched strings, but there are predicts. (Not sure if this happens though)
    } else {
      result.add(
        TextSpan(
          text: prediction.description,
          style: regularStyle,
        ),
      );
    }

    return result;
  }
}
