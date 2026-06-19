import '../../domain/entities/laropay_link_request.dart';
import '../models/laropay_link_model.dart';

abstract interface class LaropayLinkRemoteDataSource {
  Future<LaropayLinkModel> generateLink(LaropayLinkRequest request);
}
