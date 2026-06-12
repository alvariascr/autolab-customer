import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/laropay_link.dart';
import '../entities/laropay_link_request.dart';

abstract interface class LaropayLinkRepository {
  Future<Either<Failure, LaropayLink>> generateLink(LaropayLinkRequest request);
}
