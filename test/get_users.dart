import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Connecting to Supabase...');
  final supabase = await Supabase.initialize(
    url: 'https://zmplunreqqmvqoyrrceq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptcGx1bnJlcXFtdnFveXJyY2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MzE4NzMsImV4cCI6MjA5MjAwNzg3M30.JYD7vP-vfHgyR7lESXqhXvpVPDy-RTNMgTCS_R5XP7o',
  );
  
  try {
    print('Fetching profiles...');
    final List<dynamic> profiles = await supabase.client.from('profiles').select();
    if (profiles.isEmpty) {
      print('No profiles found.');
    } else {
      print('\nFound ${profiles.length} user profiles:');
      for (final profile in profiles) {
        print('-----------------------------------------');
        print('ID: \${profile[\'id\']}');
        print('Full Name: \${profile[\'full_name\']}');
        print('Role: \${profile[\'role\']}');
        print('Created At: \${profile[\'created_at\']}');
      }
      print('-----------------------------------------');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
