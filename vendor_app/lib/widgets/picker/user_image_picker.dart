import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker(this.imagePickFn, {super.key});

  final void Function(File pickedImage) imagePickFn;

  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  XFile? _pickedImage;

  void _pickImage() async {
    FocusScope.of(context).unfocus();

    final source = await showDialog<ImageSource?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pick image from'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
            child: const Text('Camera'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source == null) return;

    final pickedImageFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedImageFile == null) return;

    setState(() {
      _pickedImage = pickedImageFile;
    });
    widget.imagePickFn(File(pickedImageFile.path));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (_pickedImage != null)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: Text(
            _pickedImage == null ? 'Add Image' : 'Change Image',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
