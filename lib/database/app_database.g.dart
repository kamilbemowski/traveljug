// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceMeta = const VerificationMeta('pace');
  @override
  late final GeneratedColumn<String> pace = GeneratedColumn<String>(
    'pace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('intensive'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    destination,
    startDate,
    endDate,
    pace,
    createdAt,
    updatedAt,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('pace')) {
      context.handle(
        _paceMeta,
        pace.isAcceptableOrUnknown(data['pace']!, _paceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      pace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pace'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final int id;
  final String name;
  final String destination;

  /// Optional per FR-001 — aspirational/someday trips may omit dates.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Stored as [TravelPace.name], default `intensive`.
  final String pace;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional — no FR reference; convenience for future UI.
  final String? imageUrl;
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.pace,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['destination'] = Variable<String>(destination);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['pace'] = Variable<String>(pace);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      name: Value(name),
      destination: Value(destination),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      pace: Value(pace),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      destination: serializer.fromJson<String>(json['destination']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      pace: serializer.fromJson<String>(json['pace']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'destination': serializer.toJson<String>(destination),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'pace': serializer.toJson<String>(pace),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  Trip copyWith({
    int? id,
    String? name,
    String? destination,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    String? pace,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> imageUrl = const Value.absent(),
  }) => Trip(
    id: id ?? this.id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    pace: pace ?? this.pace,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      pace: data.pace.present ? data.pace.value : this.pace,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('destination: $destination, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('pace: $pace, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    destination,
    startDate,
    endDate,
    pace,
    createdAt,
    updatedAt,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.name == this.name &&
          other.destination == this.destination &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.pace == this.pace &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.imageUrl == this.imageUrl);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> destination;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<String> pace;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> imageUrl;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.destination = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.pace = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String destination,
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.pace = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.imageUrl = const Value.absent(),
  }) : name = Value(name),
       destination = Value(destination);
  static Insertable<Trip> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? destination,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? pace,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (destination != null) 'destination': destination,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (pace != null) 'pace': pace,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? destination,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<String>? pace,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? imageUrl,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pace: pace ?? this.pace,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (pace.present) {
      map['pace'] = Variable<String>(pace.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('destination: $destination, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('pace: $pace, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $AttractionsTable extends Attractions
    with TableInfo<$AttractionsTable, Attraction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    durationMin,
    priority,
    position,
    tripId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attractions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attraction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attraction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attraction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_id'],
      )!,
    );
  }

  @override
  $AttractionsTable createAlias(String alias) {
    return $AttractionsTable(attachedDatabase, alias);
  }
}

class Attraction extends DataClass implements Insertable<Attraction> {
  final int id;
  final String name;

  /// Stored as [AttractionCategory.name], default `other`.
  final String category;

  /// Visit duration in minutes, required per FR-003.
  final int durationMin;

  /// Three-tier priority: 0 = must-have, 1 = nice-to-have, 2 = optional.
  /// Default = 1 (nice-to-have). Labels TBD per PRD Open Question #2.
  final int priority;

  /// Ordering within a trip per FR-004.
  final int position;

  /// Foreign key to [Trips] — cascade delete when trip is removed.
  final int tripId;
  const Attraction({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMin,
    required this.priority,
    required this.position,
    required this.tripId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['duration_min'] = Variable<int>(durationMin);
    map['priority'] = Variable<int>(priority);
    map['position'] = Variable<int>(position);
    map['trip_id'] = Variable<int>(tripId);
    return map;
  }

  AttractionsCompanion toCompanion(bool nullToAbsent) {
    return AttractionsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      durationMin: Value(durationMin),
      priority: Value(priority),
      position: Value(position),
      tripId: Value(tripId),
    );
  }

  factory Attraction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attraction(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      priority: serializer.fromJson<int>(json['priority']),
      position: serializer.fromJson<int>(json['position']),
      tripId: serializer.fromJson<int>(json['tripId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'durationMin': serializer.toJson<int>(durationMin),
      'priority': serializer.toJson<int>(priority),
      'position': serializer.toJson<int>(position),
      'tripId': serializer.toJson<int>(tripId),
    };
  }

  Attraction copyWith({
    int? id,
    String? name,
    String? category,
    int? durationMin,
    int? priority,
    int? position,
    int? tripId,
  }) => Attraction(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    durationMin: durationMin ?? this.durationMin,
    priority: priority ?? this.priority,
    position: position ?? this.position,
    tripId: tripId ?? this.tripId,
  );
  Attraction copyWithCompanion(AttractionsCompanion data) {
    return Attraction(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      priority: data.priority.present ? data.priority.value : this.priority,
      position: data.position.present ? data.position.value : this.position,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attraction(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('position: $position, ')
          ..write('tripId: $tripId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, durationMin, priority, position, tripId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attraction &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.durationMin == this.durationMin &&
          other.priority == this.priority &&
          other.position == this.position &&
          other.tripId == this.tripId);
}

class AttractionsCompanion extends UpdateCompanion<Attraction> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> category;
  final Value<int> durationMin;
  final Value<int> priority;
  final Value<int> position;
  final Value<int> tripId;
  const AttractionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.priority = const Value.absent(),
    this.position = const Value.absent(),
    this.tripId = const Value.absent(),
  });
  AttractionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    required int durationMin,
    this.priority = const Value.absent(),
    this.position = const Value.absent(),
    required int tripId,
  }) : name = Value(name),
       durationMin = Value(durationMin),
       tripId = Value(tripId);
  static Insertable<Attraction> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? durationMin,
    Expression<int>? priority,
    Expression<int>? position,
    Expression<int>? tripId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (durationMin != null) 'duration_min': durationMin,
      if (priority != null) 'priority': priority,
      if (position != null) 'position': position,
      if (tripId != null) 'trip_id': tripId,
    });
  }

  AttractionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? category,
    Value<int>? durationMin,
    Value<int>? priority,
    Value<int>? position,
    Value<int>? tripId,
  }) {
    return AttractionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      durationMin: durationMin ?? this.durationMin,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttractionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('position: $position, ')
          ..write('tripId: $tripId')
          ..write(')'))
        .toString();
  }
}

class $TimelineOverridesTable extends TimelineOverrides
    with TableInfo<$TimelineOverridesTable, TimelineOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attractionIdMeta = const VerificationMeta(
    'attractionId',
  );
  @override
  late final GeneratedColumn<int> attractionId = GeneratedColumn<int>(
    'attraction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES attractions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userDayMeta = const VerificationMeta(
    'userDay',
  );
  @override
  late final GeneratedColumn<int> userDay = GeneratedColumn<int>(
    'user_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userPositionMeta = const VerificationMeta(
    'userPosition',
  );
  @override
  late final GeneratedColumn<int> userPosition = GeneratedColumn<int>(
    'user_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [attractionId, userDay, userPosition];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attraction_id')) {
      context.handle(
        _attractionIdMeta,
        attractionId.isAcceptableOrUnknown(
          data['attraction_id']!,
          _attractionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attractionIdMeta);
    }
    if (data.containsKey('user_day')) {
      context.handle(
        _userDayMeta,
        userDay.isAcceptableOrUnknown(data['user_day']!, _userDayMeta),
      );
    } else if (isInserting) {
      context.missing(_userDayMeta);
    }
    if (data.containsKey('user_position')) {
      context.handle(
        _userPositionMeta,
        userPosition.isAcceptableOrUnknown(
          data['user_position']!,
          _userPositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userPositionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  TimelineOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineOverride(
      attractionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attraction_id'],
      )!,
      userDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_day'],
      )!,
      userPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_position'],
      )!,
    );
  }

  @override
  $TimelineOverridesTable createAlias(String alias) {
    return $TimelineOverridesTable(attachedDatabase, alias);
  }
}

class TimelineOverride extends DataClass
    implements Insertable<TimelineOverride> {
  final int attractionId;

  /// The day index (0-based) where the user wants this attraction.
  final int userDay;

  /// The position within that day.
  final int userPosition;
  const TimelineOverride({
    required this.attractionId,
    required this.userDay,
    required this.userPosition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attraction_id'] = Variable<int>(attractionId);
    map['user_day'] = Variable<int>(userDay);
    map['user_position'] = Variable<int>(userPosition);
    return map;
  }

  TimelineOverridesCompanion toCompanion(bool nullToAbsent) {
    return TimelineOverridesCompanion(
      attractionId: Value(attractionId),
      userDay: Value(userDay),
      userPosition: Value(userPosition),
    );
  }

  factory TimelineOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineOverride(
      attractionId: serializer.fromJson<int>(json['attractionId']),
      userDay: serializer.fromJson<int>(json['userDay']),
      userPosition: serializer.fromJson<int>(json['userPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attractionId': serializer.toJson<int>(attractionId),
      'userDay': serializer.toJson<int>(userDay),
      'userPosition': serializer.toJson<int>(userPosition),
    };
  }

  TimelineOverride copyWith({
    int? attractionId,
    int? userDay,
    int? userPosition,
  }) => TimelineOverride(
    attractionId: attractionId ?? this.attractionId,
    userDay: userDay ?? this.userDay,
    userPosition: userPosition ?? this.userPosition,
  );
  TimelineOverride copyWithCompanion(TimelineOverridesCompanion data) {
    return TimelineOverride(
      attractionId: data.attractionId.present
          ? data.attractionId.value
          : this.attractionId,
      userDay: data.userDay.present ? data.userDay.value : this.userDay,
      userPosition: data.userPosition.present
          ? data.userPosition.value
          : this.userPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineOverride(')
          ..write('attractionId: $attractionId, ')
          ..write('userDay: $userDay, ')
          ..write('userPosition: $userPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attractionId, userDay, userPosition);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineOverride &&
          other.attractionId == this.attractionId &&
          other.userDay == this.userDay &&
          other.userPosition == this.userPosition);
}

class TimelineOverridesCompanion extends UpdateCompanion<TimelineOverride> {
  final Value<int> attractionId;
  final Value<int> userDay;
  final Value<int> userPosition;
  final Value<int> rowid;
  const TimelineOverridesCompanion({
    this.attractionId = const Value.absent(),
    this.userDay = const Value.absent(),
    this.userPosition = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimelineOverridesCompanion.insert({
    required int attractionId,
    required int userDay,
    required int userPosition,
    this.rowid = const Value.absent(),
  }) : attractionId = Value(attractionId),
       userDay = Value(userDay),
       userPosition = Value(userPosition);
  static Insertable<TimelineOverride> custom({
    Expression<int>? attractionId,
    Expression<int>? userDay,
    Expression<int>? userPosition,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attractionId != null) 'attraction_id': attractionId,
      if (userDay != null) 'user_day': userDay,
      if (userPosition != null) 'user_position': userPosition,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimelineOverridesCompanion copyWith({
    Value<int>? attractionId,
    Value<int>? userDay,
    Value<int>? userPosition,
    Value<int>? rowid,
  }) {
    return TimelineOverridesCompanion(
      attractionId: attractionId ?? this.attractionId,
      userDay: userDay ?? this.userDay,
      userPosition: userPosition ?? this.userPosition,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attractionId.present) {
      map['attraction_id'] = Variable<int>(attractionId.value);
    }
    if (userDay.present) {
      map['user_day'] = Variable<int>(userDay.value);
    }
    if (userPosition.present) {
      map['user_position'] = Variable<int>(userPosition.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineOverridesCompanion(')
          ..write('attractionId: $attractionId, ')
          ..write('userDay: $userDay, ')
          ..write('userPosition: $userPosition, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $AttractionsTable attractions = $AttractionsTable(this);
  late final $TimelineOverridesTable timelineOverrides =
      $TimelineOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trips,
    attractions,
    timelineOverrides,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attractions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'attractions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timeline_overrides', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      required String name,
      required String destination,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<String> pace,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> imageUrl,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> destination,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<String> pace,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> imageUrl,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttractionsTable, List<Attraction>>
  _attractionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attractions,
    aliasName: 'trips__id__attractions__trip_id',
  );

  $$AttractionsTableProcessedTableManager get attractionsRefs {
    final manager = $$AttractionsTableTableManager(
      $_db,
      $_db.attractions,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attractionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pace => $composableBuilder(
    column: $table.pace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attractionsRefs(
    Expression<bool> Function($$AttractionsTableFilterComposer f) f,
  ) {
    final $$AttractionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attractions,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttractionsTableFilterComposer(
            $db: $db,
            $table: $db.attractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pace => $composableBuilder(
    column: $table.pace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get pace =>
      $composableBuilder(column: $table.pace, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  Expression<T> attractionsRefs<T extends Object>(
    Expression<T> Function($$AttractionsTableAnnotationComposer a) f,
  ) {
    final $$AttractionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attractions,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttractionsTableAnnotationComposer(
            $db: $db,
            $table: $db.attractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, $$TripsTableReferences),
          Trip,
          PrefetchHooks Function({bool attractionsRefs})
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String> pace = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                name: name,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                pace: pace,
                createdAt: createdAt,
                updatedAt: updatedAt,
                imageUrl: imageUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String destination,
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String> pace = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                name: name,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                pace: pace,
                createdAt: createdAt,
                updatedAt: updatedAt,
                imageUrl: imageUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({attractionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attractionsRefs) db.attractions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attractionsRefs)
                    await $_getPrefetchedData<Trip, $TripsTable, Attraction>(
                      currentTable: table,
                      referencedTable: $$TripsTableReferences
                          ._attractionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TripsTableReferences(db, table, p0).attractionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tripId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, $$TripsTableReferences),
      Trip,
      PrefetchHooks Function({bool attractionsRefs})
    >;
typedef $$AttractionsTableCreateCompanionBuilder =
    AttractionsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> category,
      required int durationMin,
      Value<int> priority,
      Value<int> position,
      required int tripId,
    });
typedef $$AttractionsTableUpdateCompanionBuilder =
    AttractionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> category,
      Value<int> durationMin,
      Value<int> priority,
      Value<int> position,
      Value<int> tripId,
    });

final class $$AttractionsTableReferences
    extends BaseReferences<_$AppDatabase, $AttractionsTable, Attraction> {
  $$AttractionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('attractions__trip_id__trips__id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<int>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TimelineOverridesTable, List<TimelineOverride>>
  _timelineOverridesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timelineOverrides,
        aliasName: 'attractions__id__timeline_overrides__attraction_id',
      );

  $$TimelineOverridesTableProcessedTableManager get timelineOverridesRefs {
    final manager = $$TimelineOverridesTableTableManager(
      $_db,
      $_db.timelineOverrides,
    ).filter((f) => f.attractionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timelineOverridesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AttractionsTableFilterComposer
    extends Composer<_$AppDatabase, $AttractionsTable> {
  $$AttractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> timelineOverridesRefs(
    Expression<bool> Function($$TimelineOverridesTableFilterComposer f) f,
  ) {
    final $$TimelineOverridesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineOverrides,
      getReferencedColumn: (t) => t.attractionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineOverridesTableFilterComposer(
            $db: $db,
            $table: $db.timelineOverrides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AttractionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttractionsTable> {
  $$AttractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttractionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttractionsTable> {
  $$AttractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> timelineOverridesRefs<T extends Object>(
    Expression<T> Function($$TimelineOverridesTableAnnotationComposer a) f,
  ) {
    final $$TimelineOverridesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineOverrides,
          getReferencedColumn: (t) => t.attractionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineOverridesTableAnnotationComposer(
                $db: $db,
                $table: $db.timelineOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AttractionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttractionsTable,
          Attraction,
          $$AttractionsTableFilterComposer,
          $$AttractionsTableOrderingComposer,
          $$AttractionsTableAnnotationComposer,
          $$AttractionsTableCreateCompanionBuilder,
          $$AttractionsTableUpdateCompanionBuilder,
          (Attraction, $$AttractionsTableReferences),
          Attraction,
          PrefetchHooks Function({bool tripId, bool timelineOverridesRefs})
        > {
  $$AttractionsTableTableManager(_$AppDatabase db, $AttractionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttractionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttractionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttractionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> tripId = const Value.absent(),
              }) => AttractionsCompanion(
                id: id,
                name: name,
                category: category,
                durationMin: durationMin,
                priority: priority,
                position: position,
                tripId: tripId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> category = const Value.absent(),
                required int durationMin,
                Value<int> priority = const Value.absent(),
                Value<int> position = const Value.absent(),
                required int tripId,
              }) => AttractionsCompanion.insert(
                id: id,
                name: name,
                category: category,
                durationMin: durationMin,
                priority: priority,
                position: position,
                tripId: tripId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttractionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tripId = false, timelineOverridesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (timelineOverridesRefs) db.timelineOverrides,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tripId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.tripId,
                                    referencedTable:
                                        $$AttractionsTableReferences
                                            ._tripIdTable(db),
                                    referencedColumn:
                                        $$AttractionsTableReferences
                                            ._tripIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (timelineOverridesRefs)
                        await $_getPrefetchedData<
                          Attraction,
                          $AttractionsTable,
                          TimelineOverride
                        >(
                          currentTable: table,
                          referencedTable: $$AttractionsTableReferences
                              ._timelineOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AttractionsTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineOverridesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.attractionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AttractionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttractionsTable,
      Attraction,
      $$AttractionsTableFilterComposer,
      $$AttractionsTableOrderingComposer,
      $$AttractionsTableAnnotationComposer,
      $$AttractionsTableCreateCompanionBuilder,
      $$AttractionsTableUpdateCompanionBuilder,
      (Attraction, $$AttractionsTableReferences),
      Attraction,
      PrefetchHooks Function({bool tripId, bool timelineOverridesRefs})
    >;
typedef $$TimelineOverridesTableCreateCompanionBuilder =
    TimelineOverridesCompanion Function({
      required int attractionId,
      required int userDay,
      required int userPosition,
      Value<int> rowid,
    });
typedef $$TimelineOverridesTableUpdateCompanionBuilder =
    TimelineOverridesCompanion Function({
      Value<int> attractionId,
      Value<int> userDay,
      Value<int> userPosition,
      Value<int> rowid,
    });

final class $$TimelineOverridesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimelineOverridesTable,
          TimelineOverride
        > {
  $$TimelineOverridesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AttractionsTable _attractionIdTable(_$AppDatabase db) => db
      .attractions
      .createAlias('timeline_overrides__attraction_id__attractions__id');

  $$AttractionsTableProcessedTableManager get attractionId {
    final $_column = $_itemColumn<int>('attraction_id')!;

    final manager = $$AttractionsTableTableManager(
      $_db,
      $_db.attractions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attractionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimelineOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineOverridesTable> {
  $$TimelineOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userDay => $composableBuilder(
    column: $table.userDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userPosition => $composableBuilder(
    column: $table.userPosition,
    builder: (column) => ColumnFilters(column),
  );

  $$AttractionsTableFilterComposer get attractionId {
    final $$AttractionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attractionId,
      referencedTable: $db.attractions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttractionsTableFilterComposer(
            $db: $db,
            $table: $db.attractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineOverridesTable> {
  $$TimelineOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userDay => $composableBuilder(
    column: $table.userDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userPosition => $composableBuilder(
    column: $table.userPosition,
    builder: (column) => ColumnOrderings(column),
  );

  $$AttractionsTableOrderingComposer get attractionId {
    final $$AttractionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attractionId,
      referencedTable: $db.attractions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttractionsTableOrderingComposer(
            $db: $db,
            $table: $db.attractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineOverridesTable> {
  $$TimelineOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userDay =>
      $composableBuilder(column: $table.userDay, builder: (column) => column);

  GeneratedColumn<int> get userPosition => $composableBuilder(
    column: $table.userPosition,
    builder: (column) => column,
  );

  $$AttractionsTableAnnotationComposer get attractionId {
    final $$AttractionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attractionId,
      referencedTable: $db.attractions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttractionsTableAnnotationComposer(
            $db: $db,
            $table: $db.attractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineOverridesTable,
          TimelineOverride,
          $$TimelineOverridesTableFilterComposer,
          $$TimelineOverridesTableOrderingComposer,
          $$TimelineOverridesTableAnnotationComposer,
          $$TimelineOverridesTableCreateCompanionBuilder,
          $$TimelineOverridesTableUpdateCompanionBuilder,
          (TimelineOverride, $$TimelineOverridesTableReferences),
          TimelineOverride,
          PrefetchHooks Function({bool attractionId})
        > {
  $$TimelineOverridesTableTableManager(
    _$AppDatabase db,
    $TimelineOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> attractionId = const Value.absent(),
                Value<int> userDay = const Value.absent(),
                Value<int> userPosition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineOverridesCompanion(
                attractionId: attractionId,
                userDay: userDay,
                userPosition: userPosition,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int attractionId,
                required int userDay,
                required int userPosition,
                Value<int> rowid = const Value.absent(),
              }) => TimelineOverridesCompanion.insert(
                attractionId: attractionId,
                userDay: userDay,
                userPosition: userPosition,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimelineOverridesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attractionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (attractionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.attractionId,
                                referencedTable:
                                    $$TimelineOverridesTableReferences
                                        ._attractionIdTable(db),
                                referencedColumn:
                                    $$TimelineOverridesTableReferences
                                        ._attractionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimelineOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineOverridesTable,
      TimelineOverride,
      $$TimelineOverridesTableFilterComposer,
      $$TimelineOverridesTableOrderingComposer,
      $$TimelineOverridesTableAnnotationComposer,
      $$TimelineOverridesTableCreateCompanionBuilder,
      $$TimelineOverridesTableUpdateCompanionBuilder,
      (TimelineOverride, $$TimelineOverridesTableReferences),
      TimelineOverride,
      PrefetchHooks Function({bool attractionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$AttractionsTableTableManager get attractions =>
      $$AttractionsTableTableManager(_db, _db.attractions);
  $$TimelineOverridesTableTableManager get timelineOverrides =>
      $$TimelineOverridesTableTableManager(_db, _db.timelineOverrides);
}
