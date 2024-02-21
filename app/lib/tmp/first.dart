// import 'package:flutter/material.dart';

// class TeamMember {
//   String name;
//   String role;

//   TeamMember({required this.name, required this.role});

//   int getNameLength() {
//     int count = 0;
//     for (int i = 0; i < name.length; i++) {
//       count++;
//     }
//     return count;
//   }
// }

// class WorkItem {
//   String title;
//   bool isDone;

//   WorkItem({required this.title, this.isDone = false});

//   String getStatus() {
//     return isDone ? 'Done' : 'Not Done';
//   }
// }

// class Task extends WorkItem {
//   String description;
//   TeamMember? assignedTo;

//   Task({
//     required String title,
//     required this.description,
//     bool isDone = false,
//     this.assignedTo,
//   }) : super(title: title, isDone: isDone);

//   void assignTo(TeamMember member) {
//     assignedTo = member;
//   }
// }

// class Project extends WorkItem {
//   List<Task> tasks;
//   List<TeamMember> teamMembers;

//   Project({
//     required String name,
//     required this.tasks,
//     required this.teamMembers,
//     bool isDone = false,
//   }) : super(title: name, isDone: isDone);
// }

// void main() {
//   TeamMember teamMember1 = TeamMember(name: 'Alice', role: 'Developer');
//   TeamMember teamMember2 = TeamMember(name: 'Bob', role: 'Designer');
//   TeamMember teamMember3 = TeamMember(name: 'Auychai', role: 'Designer');

//   Task task1 = Task(
//       title: 'Implement Feature A', description: 'Write code for Feature A');
//   Task task2 = Task(
//       title: 'Design User Interface',
//       description: 'Create UI mockups for the app');
//   Task task3 = Task(title: 'Sleeping all day', description: '24:00 o-clock');

//   task1.assignTo(teamMember1);
//   task2.assignTo(teamMember2);
//   task3.assignTo(teamMember3);

//   task1.isDone = true;

//   Project project = Project(
//     name: 'TEAM PROJECT',
//     tasks: [task1, task2, task3],
//     teamMembers: [teamMember1, teamMember2, teamMember3],
//   );

//   runApp(MyApp(project: project));
// }

// class MyApp extends StatelessWidget {
//   final Project project;

//   const MyApp({super.key, required this.project});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Project Details'),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Text(
//                 'Project Name: ${project.title}',
//                 style:
//                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Team Members: ${project.teamMembers.map((member) => member.name).join(", ")}',
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Tasks:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Column(
//                 children: project.tasks.map((task) {
//                   return Column(
//                     children: [
//                       Text('${task.title} - ${task.getStatus()}'),
//                       Text('Task detail : ${task.description}'),
//                       if (task.assignedTo != null)
//                         Text('Assigned to: ${task.assignedTo!.name}'),
//                       Text('Name length: ${task.assignedTo!.getNameLength()}'),
//                       const SizedBox(height: 8),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
