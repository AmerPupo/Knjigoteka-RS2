import '../models/branch.dart';
import 'base_provider.dart';

class BranchProvider extends BaseProvider<Branch> {
  BranchProvider() : super('Branches');

  @override
  Branch fromJson(data) => Branch.fromJson(data);

  Future<List<Branch>> searchBranches({String? fts}) async {
    final params = <String, dynamic>{};
    if (fts != null && fts.isNotEmpty) params['fts'] = fts;
    return getAll(params: params);
  }
}
