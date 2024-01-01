import 'dart:convert';

import 'package:aquaguard/Components/MyAppBar.dart';
import 'package:aquaguard/Models/userResponse.dart';
import 'package:aquaguard/Screens/user/detailUser.dart';
import 'package:aquaguard/Services/userService.dart';
import 'package:aquaguard/Utils/constantes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late List<UserResponse> userArray = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final storage = FlutterSecureStorage();
      var id = await storage.read(key: "id");

      var users = await UserService().fetchUsers(id!);
      setState(() {
        userArray = users;
      });
    } catch (error) {
      print('Error getting users: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userArray != null) {
      return Scaffold(
          appBar: MyAppBar(),
          body: ListView(children: [
            Container(
                height: MediaQuery.of(context).size.height * .9,
                width: MediaQuery.of(context).size.width * .95,
                padding: const EdgeInsets.all(15),
                child: ListView.builder(
                    itemCount: userArray.length,
                    itemBuilder: (context, index) {
                      bool isActivated = userArray[index].isActivated ?? false;
                      Color indicatorColor = isActivated ? Colors.green : Colors.red;
                      String activationText = isActivated ? 'Activated' : 'Desactivated';
                      return StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 6.0,
                            shadowColor: const Color(0xff0d4f70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  child: CircleAvatar(
                                    radius: 80,
                                    child: ClipOval(
                                      child: userArray[index].image != null
                                          ? Image.network(
                                        '${Constantes.imageUrl}/${userArray[index].image!}',
                                        fit: BoxFit.cover,
                                        width: MediaQuery.of(context).size.width * .45,
                                        height: MediaQuery.of(context).size.height * .45,
                                      )
                                          : Placeholder(), // Replace with a placeholder widget or handle accordingly
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        userArray[index].username!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        userArray[index].email!,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        'Role: ${userArray[index].role}',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: userArray[index].role == 'admin'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (userArray[index].bannedUntil != null &&
                                          userArray[index].bannedUntil!.isAfter(DateTime.now()))
                                        Text(
                                          'Banned until: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(userArray[index].bannedUntil!)}',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(
                                        activationText,
                                        style: TextStyle(
                                          color: indicatorColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'Delete') {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Confirm Ban'),
                                                content: const Text(
                                                    'Are you sure you want to ban this user?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Response? res =
                                                      await UserService()
                                                          .banUser(
                                                          userArray[
                                                          index]
                                                              .id!);
                                                      Navigator.pop(context);

                                                      if (res?.statusCode ==
                                                          200) {
                                                        print(userArray);

                                                        setState(() {
                                                          userArray.remove(
                                                              userArray[index]);
                                                        });
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  "Information"),
                                                              content: const Text(
                                                                  "User successfully banned for 7 days!"),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            context),
                                                                    child: const Text(
                                                                        "Dismiss"))
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      } else {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  "Error"),
                                                              content: const Text(
                                                                  "User could not be banned!"),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            context),
                                                                    child: const Text(
                                                                        "Dismiss"))
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Ban',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 16,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else if (value == 'Details') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => DetailUser(user: userArray[index])),
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        if (userArray[index].role == 'admin') {
                                          return [
                                            const PopupMenuItem<String>(
                                              value: 'Details',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.info,
                                                  color: Colors.blueAccent,
                                                ),
                                                title: Text(
                                                  'Details',
                                                  style: TextStyle(color: Colors.blueAccent),
                                                ),
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'Ban',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.block,
                                                  color: Colors.red,
                                                ),
                                                title: Text(
                                                  'Ban',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          ];
                                        } else {
                                          return [
                                            const PopupMenuItem<String>(
                                              value: 'Details',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.info,
                                                  color: Colors.blueAccent,
                                                ),
                                                title: Text(
                                                  'Details',
                                                  style: TextStyle(color: Colors.blueAccent),
                                                ),
                                              ),
                                            ),
                                          ];
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }))
          ]));
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
