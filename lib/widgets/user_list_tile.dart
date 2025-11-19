// User List Tile Widget
// Related: T084, US6
// Displays user information in a list tile format

import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserListTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: user.isAdmin ? Colors.orange : Colors.blue,
                child: Text(
                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Creado: ${_formatDate(user.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user.isDeleted) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.block, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Eliminado: ${_formatDate(user.deletedAt!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      user.isAdmin ? 'Admin' : 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: user.isAdmin ? Colors.orange : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (!user.isDeleted && onDelete != null) ...[
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Eliminar usuario',
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
