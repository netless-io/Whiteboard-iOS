
#import <Foundation/Foundation.h>

/**
 * Supported logging severities of SDK
 */
typedef NS_ENUM(NSInteger, FpaLogLevel) {
    /**
     FpaProxyServiceConfig any log file.
     */
    FpaLogLevelNoLogOutput = 0,
    /**
     * 1 : Output log files of the INFO level.
     */
    FpaLogLevelInfo = 1,
    /**
     * 2 : Output log files of the WARN level.
     */
    FpaLogLevelWarning = 2,
    /**
     * 4 : Output log files of the ERROR level.
     */
    FpaLogLevelError = 4,
    /**
     * 8 : Output log files of the FATAL level.
     */
    FpaLogLevelFatal = 8,
};

typedef NS_ENUM(NSInteger, FpaFailedReason) {
    /**
     * Query dns failed(convert request url to ip failed)
     */
    FpaFailedReasonDnsQuery = -101,
    /**
     * Create socket failed
     */
    FpaFailedReasonSocketCreateFailed = -102,
    /**
     * Connect socket failed
     */
    FpaFailedReasonSocketConnect = -103,
    /**
     * Connect remote server timeout(most use at NOT fallback)
     */
    FpaFailedReasonConnectTimeout = -104,
    /**
     * Not match a chain id(most use at http)
     */
    FpaFailedReasonNoChainIdMatch = -105,
    /**
     * Failed to read data
     */
    FpaFailedReasonDataRead = -106,
    /**
     * Failed to write data
     */
    FpaFailedReasonDataWrite = -107,

    /**
     * Call too frequently
     */
    FpaFailedReasonTooFrequenty = -108,

    /**
     * Service core connect too many connections
     */
    FpaFailedReasonTooManyConnections = -109,
};

/**
 * Error code return value of Fpa
 */
typedef NS_ENUM(NSInteger, FpaError) {
    /**
     * Everything is OK, No error happen
     */
    FpaErrorNone = 0,
    /**
     * Bad parameters when call function
     */
    FpaErrorInvalidArgument = -1,
    /**
     * No memory to allocate object
     */
    FpaErrorNoMemory = -2,
    /**
     * Not init
     */
    FpaErrorNotInitialized = -3,
    /**
     * Initialize failed
     */
    FpaErrorCoreInitializeFailed = -4,
    /**
     * Unable to bind a socket port
     */
    FpaErrorUnableBindSocketPort = -5,
};

__attribute__((visibility("default"))) @interface FpaProxyServiceConfig : NSObject
/**
 * The appId of FpaProxyService.
 *
 * The App ID issued by Agora for app developers, reference to https://docs.agora.io/cn/Agora%20Platform/token#get-an-app-id
 */
@property (nonatomic, copy) NSString * _Nonnull appId;
/**
 * The token of FpaProxyService.
 *
 * Token used for authentication generated on the app server. If your project uses App ID authentication, you need to pass in your App ID. If you use App ID + Token authentication, you need to pass in the Token you generated on the App server.
 */
@property (nonatomic, copy) NSString * _Nullable token;
/**
 *  The logging severities of SDK, default FpaLogLevelNoLogOutput.
 */
@property (nonatomic, assign) FpaLogLevel logLevel;
/**
 *  The filesize of SDK log in kb.
 */
@property (nonatomic, assign) NSInteger fileSize;
/**
 *  SDK log path, Must be an absolute path.
 */
@property (nonatomic, copy) NSString * _Nonnull logFilePath;

@end

__attribute__((visibility("default"))) @interface FpaChainInfo : NSObject

@property (nonatomic, copy) NSString * _Nonnull address;

@property (nonatomic, assign) NSInteger port;

@property (nonatomic, assign) NSInteger chainId;

@property (nonatomic, assign) BOOL enableFallback;

+ (FpaChainInfo *_Nonnull)fpaChainInfoWithChainId:(NSInteger)chainId
                                          address:(NSString *_Nonnull)address
                                             port:(NSInteger)port
                                   enableFallback:(BOOL)enableFallback;

@end

__attribute__((visibility("default"))) @interface FpaProxyServiceDiagnosisInfo : NSObject

@property (nonatomic, copy) NSString * _Nonnull installId;

@property (nonatomic, copy) NSString * _Nonnull instanceId;

@end

__attribute__((visibility("default"))) @interface FpaHttpProxyChainConfig : NSObject

@property (nonatomic, strong) NSArray <FpaChainInfo *>* _Nonnull chainArray;

@property (nonatomic, assign) BOOL fallbackWhenNoChainAvailable;

@end

__attribute__((visibility("default"))) @interface FpaProxyServiceConnectionInfo : NSObject

@property (nonatomic, copy) NSString * _Nullable dstIpOrDomain;
@property (nonatomic, assign) NSInteger dstPort;
@property (nonatomic, assign) NSInteger localPort;
@property (nonatomic, copy) NSString * _Nullable connectionId;
@property (nonatomic, copy) NSString * _Nullable proxyType;

@end

@class FpaProxyService;
@protocol FpaProxyServiceDelegate <NSObject>

/**
 * Success of once FPA call(NOT include fallback)
 * @param connectionInfo Information of FpaProxyConnectionInfo
 */
- (void)onAccelerationSuccess:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo;
/**
 * Connect to fpa success
 * @param connectionInfo Information of FpaProxyConnectionInfo
 */
- (void)onConnected:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo;
/**
 * Error happen and fallback when connect(MEAN: will try fallback)
 * @param info Information of FpaProxyConnectionInfo
 * @param reason Reason code of this failed
 */
- (void)onDisconnectedAndFallback:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo reason:(FpaFailedReason)reason;
/**
 * Error happen and not fallback when connect(MEAN: not fallback, end of this request)
 * @param connectionInfo Information of FpaProxyConnectionInfo
 * @param reason Reason code of this failed
 */
- (void)onConnectionFailed:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo reason:(FpaFailedReason)reason;

@end


__attribute__((visibility("default"))) @interface FpaProxyService : NSObject

/**
 * Initialize FpaProxyService as a singleton object.
 * @return the FpaProxyService instance.
 */
+ (FpaProxyService * _Nonnull)sharedFpaProxyService;

/**
 * Create FpaProxyService sharedInstance setup configs and delegate object.
 * @param config the config of FpaProxyService, see `FpaProxyServiceConfig`
 * @return see `FpaError`
 * = 0: start succeed.
 * < 0: start failed. see `FpaError`.
 */
- (int)startWithConfig:(FpaProxyServiceConfig * _Nonnull)config;

/**
 * Get the currently used HTTP/HTTPS local proxy port
 * @return 
 * > 0 : availiable port.
 * <0 : invaild value, see `FpaError`
 */
- (int)httpProxyPort;

/**
 * Get the currently used Transparent proxy port
 * @return
 * > 0 : availiable port.
 * < 0 : invaild value, see `FpaError`
 */
- (int)getTransparentProxyPortWithChainInfo:(FpaChainInfo *_Nonnull)info;


/**
 * @brief Set or update the chain configuration of the http proxy
 *
 * @param chainConfig See `FpaHttpProxyChainConfig`
 * @return int 0: Success. < 0: Failure.
 */
- (int)setOrUpdateHttpProxyChainConfig:(FpaHttpProxyChainConfig *_Nullable)chainConfig;

/**
 * Configure SDK through JSON String to provide technical preview or special customization functions.
 * @return
 * = 0: setup succeed.
 * < 0: setup failed. see `FpaError`
 */
- (int)setParameters:(NSString * _Nonnull)param;

/**
 * Stop FpaProxyService. it will destroy the internally created proxy server and acceleration module.
 * @return
 * = 0: succeed.
 * < 0: failed. see `FpaError`
 */
- (int)stop;

/**
 * Set up a delegate object to listen to FpaProxyService proxy event callbacks
 * @param delegate delegate object
 */
- (int)setupDelegate:(id<FpaProxyServiceDelegate> _Nullable)delegate;

/**
 * Gets the FPA SDK version.
 *
 * @return The version of the current SDK in the string format.
 */
+ (NSString * _Nonnull)getSdkVersion;

/**
 * Gets the FPA SDK build info.
 *
 * @return The version of the current SDK in the string format.
 */
+ (NSString * _Nonnull)getSdkBuildInfo;

/**
 * Get information about diagnosis
 *
 * @return see `FpaProxyServiceDiagnosisInfo`
 */
- (FpaProxyServiceDiagnosisInfo* _Nullable)diagnosisInfo;

@end

