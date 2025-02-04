// Package imports:
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceStoragePermissionState extends Equatable {
  const DeviceStoragePermissionState({
    required this.storagePermission,
    required this.isNotificationRead,
  });

  final PermissionStatus storagePermission;
  final bool isNotificationRead;

  DeviceStoragePermissionState copyWith({
    PermissionStatus? storagePermission,
    bool? isNotificationRead,
  }) =>
      DeviceStoragePermissionState(
        storagePermission: storagePermission ?? this.storagePermission,
        isNotificationRead: isNotificationRead ?? this.isNotificationRead,
      );

  @override
  List<Object> get props => [storagePermission, isNotificationRead];
}

abstract class DeviceStoragePermissionEvent extends Equatable {
  const DeviceStoragePermissionEvent();
}

class DeviceStoragePermissionFetched extends DeviceStoragePermissionEvent {
  @override
  List<Object?> get props => [];
}

class DeviceStoragePermissionRequested extends DeviceStoragePermissionEvent {
  @override
  List<Object?> get props => [];
}

class DeviceStorageNotificationDisplayStatusChanged
    extends DeviceStoragePermissionEvent {
  const DeviceStorageNotificationDisplayStatusChanged({
    required this.isDisplay,
  });

  final bool isDisplay;

  @override
  List<Object?> get props => [isDisplay];
}

class DeviceStoragePermissionBloc
    extends Bloc<DeviceStoragePermissionEvent, DeviceStoragePermissionState> {
  DeviceStoragePermissionBloc({
    required PermissionStatus initialStatus,
  }) : super(DeviceStoragePermissionState(
          storagePermission: initialStatus,
          isNotificationRead: false,
        )) {
    on<DeviceStoragePermissionFetched>(
      (event, emit) async {
        final status = await Permission.storage.status;
        emit(state.copyWith(storagePermission: status));
      },
      transformer: droppable(),
    );

    on<DeviceStoragePermissionRequested>(
      (event, emit) async {
        final status = await Permission.storage.request();
        emit(state.copyWith(
          storagePermission: status,
          isNotificationRead: false,
        ));
      },
      transformer: droppable(),
    );

    on<DeviceStorageNotificationDisplayStatusChanged>((event, emit) {
      emit(state.copyWith(isNotificationRead: event.isDisplay));
    });
  }
}
