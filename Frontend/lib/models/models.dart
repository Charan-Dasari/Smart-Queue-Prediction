import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum ServiceCategory { hospital, bank, governmentOffice, college, other }
enum AppointmentStatus { upcoming, inQueue, serving, completed, cancelled }
enum NotificationType { booking, queue, reminder, system, ai }
enum CounterStatus { active, onBreak, offline }
enum UserRole { user, admin, staff, superAdmin }
enum QueueTimelineStep { booked, checkedIn, waiting, serving, completed }

// ─── Models ──────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  String name;
  String email;
  String mobile;
  String password;
  UserRole role;
  String providerId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    this.role = UserRole.user,
    this.providerId = 'h1',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      password: '',
      role: UserRole.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['role'] ?? 'user').toString().toLowerCase(),
          orElse: () => UserRole.user),
      providerId: json['providerId'] ?? '',
    );
  }
}

class ServiceCategoryInfo {
  final ServiceCategory category;
  final String label;
  final IconData icon;
  final Color color;
  final int providerCount;

  const ServiceCategoryInfo({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.providerCount,
  });
}

class ServiceProviderInfo {
  final String id;
  final String name;
  final ServiceCategory category;
  final String address;
  final double rating;
  final double distanceKm;
  final int activeQueueCount;
  final int estimatedWaitMinutes;
  final List<ServiceItem> services;

  const ServiceProviderInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.rating,
    required this.distanceKm,
    required this.activeQueueCount,
    required this.estimatedWaitMinutes,
    required this.services,
  });

  factory ServiceProviderInfo.fromJson(Map<String, dynamic> json) {
    return ServiceProviderInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: ServiceCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['category'] ?? 'other').toString().toLowerCase(),
          orElse: () => ServiceCategory.other),
      address: json['address'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      activeQueueCount: json['activeQueueCount'] ?? 0,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ServiceItem {
  final String id;
  final String name;
  final String description;
  final Duration avgDuration;
  final double cost;
  final bool isActive;

  int get estimatedWaitMinutes => avgDuration.inMinutes;

  const ServiceItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.avgDuration,
    this.cost = 0.0,
    this.isActive = true,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avgDuration: Duration(minutes: json['avgDurationMinutes'] ?? 15),
      cost: (json['cost'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final int availableSlots;
  final int totalSlots;
  final double crowdLevel;
  final double aiScore;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.availableSlots,
    required this.totalSlots,
    required this.crowdLevel,
    this.aiScore = 0.0,
  });

  bool get isAvailable => availableSlots > 0;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      availableSlots: json['availableSlots'] ?? 0,
      totalSlots: json['totalSlots'] ?? 0,
      crowdLevel: (json['crowdLevel'] ?? 0.0).toDouble(),
      aiScore: (json['aiScore'] ?? 0.0).toDouble(),
    );
  }
}

class Appointment {
  final String id;
  final String providerName;
  final String serviceName;
  final String tokenNumber;
  final DateTime date;
  final TimeSlot? timeSlot;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.providerName,
    required this.serviceName,
    required this.tokenNumber,
    required this.date,
    this.timeSlot,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      providerName: json['providerName'] ?? '',
      serviceName: json['serviceName'] ?? '',
      tokenNumber: json['tokenNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      timeSlot: json['timeSlot'] != null ? TimeSlot.fromJson(json['timeSlot']) : null,
      status: AppointmentStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['status'] ?? 'upcoming').toString().toLowerCase(),
          orElse: () => AppointmentStatus.upcoming),
    );
  }
}

class QueueToken {
  final String id;
  final String tokenNumber;
  final String providerName;
  final String serviceName;
  final int queuePosition;
  final int currentServing;
  final int estimatedWaitMinutes;
  final AppointmentStatus status;
  final DateTime createdAt;

  const QueueToken({
    required this.id,
    required this.tokenNumber,
    required this.providerName,
    required this.serviceName,
    required this.queuePosition,
    required this.currentServing,
    required this.estimatedWaitMinutes,
    required this.status,
    required this.createdAt,
  });

  factory QueueToken.fromJson(Map<String, dynamic> json) {
    return QueueToken(
      id: json['id'] ?? '',
      tokenNumber: json['tokenNumber'] ?? '',
      providerName: json['providerName'] ?? '',
      serviceName: json['serviceName'] ?? '',
      queuePosition: json['position'] ?? 0,
      currentServing: json['currentServing'] ?? 0,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
      status: AppointmentStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['status'] ?? 'inqueue').toString().toLowerCase(),
          orElse: () => AppointmentStatus.inQueue),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['type'] ?? 'system').toString().toLowerCase(),
          orElse: () => NotificationType.system),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}

class ServiceCounter {
  final int number;
  final String staffName;
  final String? activeTokenNumber;
  final CounterStatus status;
  final int todayCustomers;
  final int avgServiceMinutes;

  const ServiceCounter({
    required this.number,
    required this.staffName,
    this.activeTokenNumber,
    this.status = CounterStatus.active,
    this.todayCustomers = 0,
    this.avgServiceMinutes = 0,
  });

  factory ServiceCounter.fromJson(Map<String, dynamic> json) {
    return ServiceCounter(
      number: json['number'] ?? 0,
      staffName: json['staffName'] ?? '',
      activeTokenNumber: json['activeTokenNumber'],
      status: CounterStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['status'] ?? 'active').toString().toLowerCase(),
          orElse: () => CounterStatus.active),
      todayCustomers: json['todayCustomers'] ?? 0,
      avgServiceMinutes: json['avgServiceMinutes'] ?? 0,
    );
  }
}

class DashboardStats {
  final int totalAppointments;
  final int completedVisits;
  final int timeSavedMinutes;
  final int activeQueues;
  final int avgWaitMinutes;
  final int todayVisitors;

  const DashboardStats({
    required this.totalAppointments,
    required this.completedVisits,
    required this.timeSavedMinutes,
    required this.activeQueues,
    required this.avgWaitMinutes,
    required this.todayVisitors,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAppointments: json['totalAppointments'] ?? 0,
      completedVisits: json['completedVisits'] ?? 0,
      timeSavedMinutes: json['timeSavedMinutes'] ?? 0,
      activeQueues: json['activeQueues'] ?? 0,
      avgWaitMinutes: json['avgWaitMinutes'] ?? 0,
      todayVisitors: json['todayVisitors'] ?? 0,
    );
  }
}

class HourlyData {
  final int hour;
  final double value;

  const HourlyData({required this.hour, required this.value});

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: json['hour'] ?? 0,
      value: (json['value'] ?? 0.0).toDouble(),
    );
  }
}

class AIPrediction {
  final double crowdLevel;
  final String crowdLabel;
  final int predictedWaitMinutes;
  final int recommendedCounters;
  final List<HourlyData> hourlyForecast;

  const AIPrediction({
    required this.crowdLevel,
    required this.crowdLabel,
    required this.predictedWaitMinutes,
    required this.recommendedCounters,
    required this.hourlyForecast,
  });
}

class StaffOperator {
  final String id;
  final String name;
  final int assignedCounter;
  final CounterStatus status;
  final int todayCustomers;
  final int avgServiceMinutes;

  const StaffOperator({
    required this.id,
    required this.name,
    required this.assignedCounter,
    this.status = CounterStatus.active,
    this.todayCustomers = 0,
    this.avgServiceMinutes = 0,
  });
}
