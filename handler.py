import boto3
import face_recognition
import pickle
import os
import csv
import urllib.parse

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table_dynamo = dynamodb.Table('student_data')
input_bucket = "546proj2-1"
output_bucket = "546proj2output-1"
video_folder = "/tmp/"


#Function to read the 'encoding' file
def open_encoding(filename):
	file = open(filename, "rb")
	data = pickle.load(file)
	file.close()
	return data


def face_recognition_handler(event, context):
	# Downloading video by extracting the key created in s3 bucket
	key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'],encoding='utf-8')
	os.makedirs(video_folder)
	s3.download_file(input_bucket, key, os.path.join(video_folder, key))
	
	#ffmpeg command
	os.system('ffmpeg -i ' + os.path.join(video_folder,key) + ' -r 1 ' + video_folder + 'image-%3d.jpeg' + ' -loglevel 8')

	#frame sent to facial recognition
	image_frame_face = face_recognition.load_image_file(os.path.join(video_folder, 'image-001.jpeg'))
	face_encoding = face_recognition.face_encodings(image_frame_face)[0]

	#match encoding
	encoding_file = '/home/app/encoding'
	file = open(encoding_file, "rb")
	encoding_pool = pickle.load(file)
	file.close()

	result = None
	for encoding in enumerate(encoding_pool['encoding']):
		if face_recognition.compare_faces([encoding[1]], face_encoding)[0]:
			result = encoding_pool['name'][encoding[0]]
			break

	#get student data
	student_data = table_dynamo.get_item(Key={'name': result})['Item']
	csv_name = key.split('.')[0] + '.csv'
	with open(video_folder + csv_name, mode='w') as f:
		f.write(f"{student_data['name']}, {student_data['major']}, {student_data['year']}")
		f.close()

	#s3 upload
	s3.upload_file(video_folder + csv_name, output_bucket, csv_name)
