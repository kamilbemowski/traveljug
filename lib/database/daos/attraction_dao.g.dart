// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attraction_dao.dart';

// ignore_for_file: type=lint
mixin _$AttractionDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $AttractionsTable get attractions => attachedDatabase.attractions;
  AttractionDaoManager get managers => AttractionDaoManager(this);
}

class AttractionDaoManager {
  final _$AttractionDaoMixin _db;
  AttractionDaoManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db.attachedDatabase, _db.trips);
  $$AttractionsTableTableManager get attractions =>
      $$AttractionsTableTableManager(_db.attachedDatabase, _db.attractions);
}
