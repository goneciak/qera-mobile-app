class ApiEndpoints {
  // Base URL - zgodne z dokumentacją API: 192.168.1.178:3000/api/v1/docs
  static const String baseUrl = 'http://192.168.1.178:3000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String passwordResetRequest = '/auth/password/reset/request';
  static const String passwordResetConfirm = '/auth/password/reset/confirm';
  static const String acceptInvite = '/auth/invite/accept';

  // Rep - Profile
  static const String repMe = '/rep/me';

  // Rep - Subscription
  static const String subscriptionStatus = '/rep/subscription/status';
  static const String subscriptionCheckout = '/rep/subscription/checkout';

  // Rep - Interviews
  static const String interviews = '/rep/interviews';
  static String interviewById(String id) => '/rep/interviews/$id';
  static String interviewSubmit(String id) => '/rep/interviews/$id/submit';
  static String interviewPdf(String id) => '/rep/interviews/$id/pdf';
  static String interviewEsign(String id) => '/rep/interviews/$id/esign/create-envelope';
  static String interviewSignatureUpload(String id) => '/rep/interviews/$id/signature/manual-upload';
  static String interviewGenerateOffer(String id) => '/rep/interviews/$id/offers/generate';

  // Rep - Documents
  static const String documents = '/rep/documents';
  static String documentById(String id) => '/rep/documents/$id';
  static String documentSend(String id) => '/rep/documents/$id/send';

  // Rep - Offers
  static const String offers = '/rep/offers';
  static String offerById(String id) => '/rep/offers/$id';

  // Rep - Commissions
  static const String commissions = '/rep/commissions';

  // Rep - Files
  static const String files = '/rep/files';
  static String fileById(String id) => '/rep/files/$id';

  // Rep - Products
  static const String products = '/rep/products';
}
