import '../../../../personalization/models/user_model.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../Booking/models/booking_item_model.dart';
import '../../../Booking/models/booking_model.dart';
import '../models/tutor_model.dart';
import '../models/subject_model.dart';
import '../../../Courses/models/tutoring_session_model.dart';
import '../../../Courses/models/session_attribute_model.dart';
import '../../../Courses/models/session_variation_model.dart';

class DummyTutoringData {
  /// -- User
  static final UserModel user = UserModel(
    fullName: 'Student Example',
    email: 'student@example.com',
    phoneNumber: '+14155552671',
    profilePicture: TImages.tProfileImage,
    addresses: [],
    id: '',
    isEmailVerified: true,
    isProfileActive: true,
  );

  /// -- Bookings
  static final BookingModel bookings = BookingModel(
    bookingId: '001',
    userId: user.id,
    createdAt: DateTime.now(),
    bookings: [
      BookingItemModel(
        serviceId: '001',
        providerId: '1',
        serviceTitle: tutoringSessions[0].title,
        serviceImage: tutoringSessions[0].thumbnail,
        providerName: tutoringSessions[0].tutor?.name ?? '',
        providerImage: tutoringSessions[0].tutor?.image ?? '',
        bookingDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '10:00 AM - 11:00 AM',
        price: tutoringSessions[0].sessionVariations![0].pricePerSession,
        quantity: 1,
        isPhysical: true,
        applyDiscount: false,
      ),
      BookingItemModel(
        serviceId: '002',
        providerId: '2',
        serviceTitle: tutoringSessions[1].title,
        serviceImage: tutoringSessions[1].thumbnail,
        providerName: tutoringSessions[1].tutor?.name ?? '',
        providerImage: tutoringSessions[1].tutor?.image ?? '',
        bookingDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '2:00 PM - 3:00 PM',
        price: tutoringSessions[1].pricePerSession,
        quantity: 1,
        isPhysical: false,
        applyDiscount: true,
        negotiatedPrice: 45,
      ),
    ],
  );

  /// -- Subjects
  static final List<SubjectModel> subjects = [
    SubjectModel(
      id: '1',
      image: TImages.mathIcon,
      name: 'Mathematics',
      isFeatured: true,
    ),
    SubjectModel(
      id: '2',
      image: TImages.physicsIcon,
      name: 'Physics',
      isFeatured: true,
    ),
    SubjectModel(
      id: '3',
      image: TImages.chemistryIcon,
      name: 'Chemistry',
      isFeatured: true,
    ),
    SubjectModel(
      id: '4',
      image: TImages.csIcon,
      name: 'Computer Science',
      isFeatured: true,
    ),
    SubjectModel(
      id: '5',
      image: TImages.biologyIcon,
      name: 'Biology',
      isFeatured: true,
    ),
    SubjectModel(
      id: '6',
      image: TImages.economicsIcon,
      name: 'Economics',
      isFeatured: true,
    ),
    SubjectModel(
      id: '7',
      image: TImages.literatureIcon,
      name: 'Literature',
      isFeatured: true,
    ),
    SubjectModel(
      id: '8',
      image: TImages.engineeringIcon,
      name: 'Engineering',
      isFeatured: true,
    ),
    SubjectModel(
      id: '9',
      image: TImages.artsIcon,
      name: 'Arts & Music',
      isFeatured: true,
    ),
    SubjectModel(
      id: '10',
      image: TImages.othersIcon,
      name: 'Others',
      isFeatured: true,
    ),
  ];

  /// -- Tutors
  static final List<TutorModel> tutors = [
    TutorModel(
      id: '1',
      name: 'Alice Johnson',
      image: TImages.tutorAlice,
      sessionsCount: 12,
      isFeatured: true,
    ),
    TutorModel(
      id: '2',
      name: 'Bob Smith',
      image: TImages.tutorBob,
      sessionsCount: 8,
      isFeatured: true,
    ),
    TutorModel(
      id: '3',
      name: 'Carol Lee',
      image: TImages.tutorCarol,
      sessionsCount: 15,
      isFeatured: true,
    ),
  ];

  /// -- Tutoring Sessions
  static final List<TutoringSessionModel> tutoringSessions = [
    TutoringSessionModel(
      id: '001',
      title: 'Basic Algebra Lecture',
      availableSeats: 10,
      pricePerSession: 50.0,
      isFeatured: true,
      thumbnail: TImages.courseMathBasics,
      description: 'Learn algebra fundamentals with examples and exercises.',
      tutor: tutors[0],
      images: [TImages.courseMathBasics],
      subjectId: '1',
      sessionAttributes: [
        SessionAttributeModel(name: 'Level', values: ['Beginner']),
        SessionAttributeModel(name: 'Duration', values: ['1hr', '2hr']),
        SessionAttributeModel(name: 'Mode', values: ['Online', 'In-Person']),
      ],
      sessionVariations: [
        SessionVariationModel(
          id: '1',
          availableSeats: 5,
          pricePerSession: 50.0,
          image: TImages.courseMathBasics,
          description: 'Beginner algebra session with Alice Johnson, 1 hour',
          sessionAttributes: {
            'Level': 'Beginner',
            'Duration': '1hr',
            'Mode': 'Online',
          },
          lectureTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
        ),
      ],
    ),
    TutoringSessionModel(
      id: '002',
      title: 'Introduction to Physics Lecture',
      availableSeats: 8,
      pricePerSession: 60.0,
      isFeatured: true,
      thumbnail: TImages.coursePhysicsIntro,
      description:
          'Physics basics explained by Bob Smith with hands-on examples.',
      tutor: tutors[1],
      images: [TImages.coursePhysicsIntro],
      subjectId: '2',
      sessionAttributes: [
        SessionAttributeModel(name: 'Level', values: ['Beginner']),
        SessionAttributeModel(name: 'Mode', values: ['Online']),
      ],
      sessionVariations: [
        SessionVariationModel(
          id: '2',
          availableSeats: 8,
          pricePerSession: 60.0,
          image: TImages.coursePhysicsIntro,
          description: 'Beginner physics session with Bob Smith, 1 hour',
          sessionAttributes: {'Level': 'Beginner', 'Mode': 'Online'},
          lectureTime: DateTime.now().add(const Duration(days: 2, hours: 14)),
        ),
      ],
    ),
    TutoringSessionModel(
      id: '003',
      title: 'Chemistry Lab Workshop',
      availableSeats: 5,
      pricePerSession: 80.0,
      isFeatured: false,
      thumbnail: TImages.courseChemistryLab,
      description: 'Practical chemistry experiments with Carol Lee.',
      tutor: tutors[2],
      images: [TImages.courseChemistryLab],
      subjectId: '3',
      sessionAttributes: [
        SessionAttributeModel(name: 'Level', values: ['Intermediate']),
        SessionAttributeModel(name: 'Mode', values: ['In-Person']),
      ],
      sessionVariations: [
        SessionVariationModel(
          id: '3',
          availableSeats: 5,
          pricePerSession: 80.0,
          image: TImages.courseChemistryLab,
          description: 'Intermediate chemistry lab with Carol Lee',
          sessionAttributes: {'Level': 'Intermediate', 'Mode': 'In-Person'},
          lectureTime: DateTime.now().add(const Duration(days: 3, hours: 16)),
        ),
      ],
    ),
  ];

  /// -- Sorting Filters
  static final sortingFilters = [
    SortFilterModel(id: '1', name: 'Name'),
    SortFilterModel(id: '2', name: 'Lowest Price'),
    SortFilterModel(id: '3', name: 'Most Popular'),
    SortFilterModel(id: '4', name: 'Highest Price'),
    SortFilterModel(id: '5', name: 'Newest'),
    SortFilterModel(id: '6', name: 'Most Suitable'),
  ];
}

class SortFilterModel {
  String id;
  String name;

  SortFilterModel({required this.id, required this.name});
}
