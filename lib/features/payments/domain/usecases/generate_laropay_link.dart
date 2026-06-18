import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/laropay_link.dart';
import '../entities/laropay_link_request.dart';
import '../repositories/laropay_link_repository.dart';

class GenerateLaropayLink {
  const GenerateLaropayLink(this._repository);

  final LaropayLinkRepository _repository;

  Future<Either<Failure, LaropayLink>> call(LaropayLinkRequest request) {
    return _repository.generateLink(request);
  }
}
