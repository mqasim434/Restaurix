// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_slip_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSalarySlipIsarCollection on Isar {
  IsarCollection<SalarySlipIsar> get salarySlipIsars => this.collection();
}

const SalarySlipIsarSchema = CollectionSchema(
  name: r'SalarySlipIsar',
  id: 4057885851649550213,
  properties: {
    r'basePay': PropertySchema(
      id: 0,
      name: r'basePay',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deductions': PropertySchema(
      id: 2,
      name: r'deductions',
      type: IsarType.double,
    ),
    r'deletedAt': PropertySchema(
      id: 3,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'deviceId': PropertySchema(
      id: 4,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'employeeId': PropertySchema(
      id: 5,
      name: r'employeeId',
      type: IsarType.string,
    ),
    r'generatedAt': PropertySchema(
      id: 6,
      name: r'generatedAt',
      type: IsarType.dateTime,
    ),
    r'generatedByUserId': PropertySchema(
      id: 7,
      name: r'generatedByUserId',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 8,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'netPay': PropertySchema(
      id: 9,
      name: r'netPay',
      type: IsarType.double,
    ),
    r'periodEnd': PropertySchema(
      id: 10,
      name: r'periodEnd',
      type: IsarType.dateTime,
    ),
    r'periodStart': PropertySchema(
      id: 11,
      name: r'periodStart',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.string,
    ),
    r'syncAction': PropertySchema(
      id: 13,
      name: r'syncAction',
      type: IsarType.string,
    ),
    r'totalHours': PropertySchema(
      id: 14,
      name: r'totalHours',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 16,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 17,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _salarySlipIsarEstimateSize,
  serialize: _salarySlipIsarSerialize,
  deserialize: _salarySlipIsarDeserialize,
  deserializeProp: _salarySlipIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'employeeId': IndexSchema(
      id: 1283453093523034672,
      name: r'employeeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'employeeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'periodStart': IndexSchema(
      id: -7133903706047263368,
      name: r'periodStart',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'periodStart',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'periodEnd': IndexSchema(
      id: -748264925685152938,
      name: r'periodEnd',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'periodEnd',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _salarySlipIsarGetId,
  getLinks: _salarySlipIsarGetLinks,
  attach: _salarySlipIsarAttach,
  version: '3.1.0+1',
);

int _salarySlipIsarEstimateSize(
  SalarySlipIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.employeeId.length * 3;
  bytesCount += 3 + object.generatedByUserId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.syncAction.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _salarySlipIsarSerialize(
  SalarySlipIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.basePay);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDouble(offsets[2], object.deductions);
  writer.writeDateTime(offsets[3], object.deletedAt);
  writer.writeString(offsets[4], object.deviceId);
  writer.writeString(offsets[5], object.employeeId);
  writer.writeDateTime(offsets[6], object.generatedAt);
  writer.writeString(offsets[7], object.generatedByUserId);
  writer.writeBool(offsets[8], object.isSynced);
  writer.writeDouble(offsets[9], object.netPay);
  writer.writeDateTime(offsets[10], object.periodEnd);
  writer.writeDateTime(offsets[11], object.periodStart);
  writer.writeString(offsets[12], object.status);
  writer.writeString(offsets[13], object.syncAction);
  writer.writeDouble(offsets[14], object.totalHours);
  writer.writeDateTime(offsets[15], object.updatedAt);
  writer.writeString(offsets[16], object.uuid);
  writer.writeLong(offsets[17], object.version);
}

SalarySlipIsar _salarySlipIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SalarySlipIsar();
  object.basePay = reader.readDouble(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deductions = reader.readDoubleOrNull(offsets[2]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[3]);
  object.deviceId = reader.readString(offsets[4]);
  object.employeeId = reader.readString(offsets[5]);
  object.generatedAt = reader.readDateTime(offsets[6]);
  object.generatedByUserId = reader.readString(offsets[7]);
  object.isSynced = reader.readBool(offsets[8]);
  object.isarId = id;
  object.netPay = reader.readDouble(offsets[9]);
  object.periodEnd = reader.readDateTime(offsets[10]);
  object.periodStart = reader.readDateTime(offsets[11]);
  object.status = reader.readString(offsets[12]);
  object.syncAction = reader.readString(offsets[13]);
  object.totalHours = reader.readDouble(offsets[14]);
  object.updatedAt = reader.readDateTime(offsets[15]);
  object.uuid = reader.readString(offsets[16]);
  object.version = reader.readLong(offsets[17]);
  return object;
}

P _salarySlipIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _salarySlipIsarGetId(SalarySlipIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _salarySlipIsarGetLinks(SalarySlipIsar object) {
  return [];
}

void _salarySlipIsarAttach(
    IsarCollection<dynamic> col, Id id, SalarySlipIsar object) {
  object.isarId = id;
}

extension SalarySlipIsarByIndex on IsarCollection<SalarySlipIsar> {
  Future<SalarySlipIsar?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  SalarySlipIsar? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<SalarySlipIsar?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<SalarySlipIsar?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(SalarySlipIsar object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(SalarySlipIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<SalarySlipIsar> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<SalarySlipIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension SalarySlipIsarQueryWhereSort
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QWhere> {
  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhere> anyPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'periodStart'),
      );
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhere> anyPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'periodEnd'),
      );
    });
  }
}

extension SalarySlipIsarQueryWhere
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QWhereClause> {
  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      employeeIdEqualTo(String employeeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'employeeId',
        value: [employeeId],
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      employeeIdNotEqualTo(String employeeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [],
              upper: [employeeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [employeeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [employeeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [],
              upper: [employeeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodStartEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'periodStart',
        value: [periodStart],
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodStartNotEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodStartGreaterThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [periodStart],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodStartLessThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [],
        upper: [periodStart],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodStartBetween(
    DateTime lowerPeriodStart,
    DateTime upperPeriodStart, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [lowerPeriodStart],
        includeLower: includeLower,
        upper: [upperPeriodStart],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodEndEqualTo(DateTime periodEnd) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'periodEnd',
        value: [periodEnd],
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodEndNotEqualTo(DateTime periodEnd) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodEnd',
              lower: [],
              upper: [periodEnd],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodEnd',
              lower: [periodEnd],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodEnd',
              lower: [periodEnd],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodEnd',
              lower: [],
              upper: [periodEnd],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodEndGreaterThan(
    DateTime periodEnd, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodEnd',
        lower: [periodEnd],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodEndLessThan(
    DateTime periodEnd, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodEnd',
        lower: [],
        upper: [periodEnd],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterWhereClause>
      periodEndBetween(
    DateTime lowerPeriodEnd,
    DateTime upperPeriodEnd, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodEnd',
        lower: [lowerPeriodEnd],
        includeLower: includeLower,
        upper: [upperPeriodEnd],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SalarySlipIsarQueryFilter
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QFilterCondition> {
  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      basePayEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basePay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      basePayGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'basePay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      basePayLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'basePay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      basePayBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'basePay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deductionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deductions',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deductionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deductions',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deductionsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deductions',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deductionsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deductions',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deductionsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deductions',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deductionsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deductions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'employeeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'employeeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeId',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      employeeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'employeeId',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedByUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedByUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedByUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedByUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'generatedByUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'generatedByUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'generatedByUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'generatedByUserId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedByUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      generatedByUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'generatedByUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      netPayEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'netPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      netPayGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'netPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      netPayLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'netPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      netPayBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'netPay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodEndEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodEndGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodEndLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodEndBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      periodStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncAction',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncAction',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncAction',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      syncActionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncAction',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      totalHoursEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      totalHoursGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      totalHoursLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      totalHoursBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalHours',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterFilterCondition>
      versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SalarySlipIsarQueryObject
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QFilterCondition> {}

extension SalarySlipIsarQueryLinks
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QFilterCondition> {}

extension SalarySlipIsarQuerySortBy
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QSortBy> {
  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByBasePay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePay', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByBasePayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePay', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByDeductions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByDeductionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByEmployeeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByGeneratedByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedByUserId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByGeneratedByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedByUserId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByNetPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByNetPayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortBySyncAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAction', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortBySyncActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAction', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByTotalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByTotalHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension SalarySlipIsarQuerySortThenBy
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QSortThenBy> {
  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByBasePay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePay', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByBasePayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePay', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByDeductions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByDeductionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByEmployeeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByGeneratedByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedByUserId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByGeneratedByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedByUserId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByNetPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByNetPayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenBySyncAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAction', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenBySyncActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAction', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByTotalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByTotalHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension SalarySlipIsarQueryWhereDistinct
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> {
  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByBasePay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basePay');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByDeductions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deductions');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByEmployeeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'employeeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedAt');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByGeneratedByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedByUserId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByNetPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netPay');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEnd');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStart');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctBySyncAction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncAction', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByTotalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalHours');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SalarySlipIsar, SalarySlipIsar, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension SalarySlipIsarQueryProperty
    on QueryBuilder<SalarySlipIsar, SalarySlipIsar, QQueryProperty> {
  QueryBuilder<SalarySlipIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<SalarySlipIsar, double, QQueryOperations> basePayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basePay');
    });
  }

  QueryBuilder<SalarySlipIsar, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SalarySlipIsar, double?, QQueryOperations> deductionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deductions');
    });
  }

  QueryBuilder<SalarySlipIsar, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<SalarySlipIsar, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<SalarySlipIsar, String, QQueryOperations> employeeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'employeeId');
    });
  }

  QueryBuilder<SalarySlipIsar, DateTime, QQueryOperations>
      generatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedAt');
    });
  }

  QueryBuilder<SalarySlipIsar, String, QQueryOperations>
      generatedByUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedByUserId');
    });
  }

  QueryBuilder<SalarySlipIsar, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<SalarySlipIsar, double, QQueryOperations> netPayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netPay');
    });
  }

  QueryBuilder<SalarySlipIsar, DateTime, QQueryOperations> periodEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEnd');
    });
  }

  QueryBuilder<SalarySlipIsar, DateTime, QQueryOperations>
      periodStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStart');
    });
  }

  QueryBuilder<SalarySlipIsar, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<SalarySlipIsar, String, QQueryOperations> syncActionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncAction');
    });
  }

  QueryBuilder<SalarySlipIsar, double, QQueryOperations> totalHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalHours');
    });
  }

  QueryBuilder<SalarySlipIsar, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<SalarySlipIsar, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<SalarySlipIsar, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
