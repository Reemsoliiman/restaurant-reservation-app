import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/notifications/notifications_cubit.dart';
import '../cubits/notifications/notifications_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsCubit()..loadNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return Center(child: Text(state.message));
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(child: Text('No notifications'));
            }

            return ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (ctx, i) {
                final notification = state.notifications[i];

                return ListTile(
                  title: Text(notification.message),
                  subtitle: notification.vendorId != null 
                      ? Text('Vendor: ${notification.vendorId}') 
                      : null,
                  trailing: IconButton(
                    icon: Icon(notification.read 
                        ? Icons.mark_email_read 
                        : Icons.mark_email_unread),
                    onPressed: () {
                      context.read<NotificationsCubit>().toggleReadStatus(
                        notification.id,
                        notification.read,
                      );
                    },
                  ),
                  isThreeLine: notification.createdAt != null,
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Notification'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            if (notification.createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('At: ${notification.createdAt!.toLocal()}'),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }

          return const Center(child: Text('No notifications'));
        },
      ),
    );
  }
}
