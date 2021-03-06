#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


PATCH_SUPEE-9767_EE_1.13.1.0_v1.sh | EE_1.13.1.0 | v1 | 226caf7 | Mon Feb 20 17:33:39 2017 +0200 | 2321b14

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
index fe358b7..67fc9f6 100644
--- app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
+++ app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
@@ -171,6 +171,11 @@ class Enterprise_CatalogEvent_Adminhtml_Catalog_EventController extends Mage_Adm
             $uploader->setAllowRenameFiles(true);
             $uploader->setAllowCreateFolders(true);
             $uploader->setFilesDispersion(false);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
         } catch (Exception $e) {
             $isUploaded = false;
         }
diff --git app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
index 6c02533..af99cae 100644
--- app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
+++ app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
@@ -173,6 +173,11 @@ class Enterprise_GiftWrapping_Model_Wrapping extends Mage_Core_Model_Abstract
             $uploader->setAllowRenameFiles(true);
             $uploader->setAllowCreateFolders(true);
             $uploader->setFilesDispersion(false);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
         } catch (Exception $e) {
             $isUploaded = false;
         }
diff --git app/code/core/Enterprise/Invitation/Model/Config.php app/code/core/Enterprise/Invitation/Model/Config.php
index 0ff6514..ebc2f22 100644
--- app/code/core/Enterprise/Invitation/Model/Config.php
+++ app/code/core/Enterprise/Invitation/Model/Config.php
@@ -41,6 +41,8 @@ class Enterprise_Invitation_Model_Config
     const XML_PATH_REGISTRATION_REQUIRED_INVITATION = 'enterprise_invitation/general/registration_required_invitation';
     const XML_PATH_REGISTRATION_USE_INVITER_GROUP = 'enterprise_invitation/general/registration_use_inviter_group';
 
+    const XML_PATH_INTERVAL = 'enterprise_invitation/general/interval';
+
     /**
      * Return max Invitation amount per send by config
      *
@@ -88,7 +90,7 @@ class Enterprise_Invitation_Model_Config
 
     /**
      * Retrieve configuration for availability of invitations
-     * on global level. Also will disallowe any functionality in admin.
+     * on global level. Also will disallow any functionality in admin.
      *
      * @param int $storeId
      * @return boolean
@@ -113,4 +115,14 @@ class Enterprise_Invitation_Model_Config
 
         return false;
     }
+
+    /**
+     * Retrieve configuration for the minimum interval between invitations
+     * @param int $storeId
+     * @return mixed
+     */
+    public function getMinInvitationPeriod($storeId = null)
+    {
+        return Mage::getStoreConfig(self::XML_PATH_INTERVAL, $storeId);
+    }
 }
diff --git app/code/core/Enterprise/Invitation/Model/Invitation.php app/code/core/Enterprise/Invitation/Model/Invitation.php
index b648cbb..a224ad1 100644
--- app/code/core/Enterprise/Invitation/Model/Invitation.php
+++ app/code/core/Enterprise/Invitation/Model/Invitation.php
@@ -453,4 +453,23 @@ class Enterprise_Invitation_Model_Invitation extends Mage_Core_Model_Abstract
         return true;
     }
 
+    /**
+     * Checks if customer invitations limit exceeded
+     * if no - returns the allowed limit
+     * @param $customerId
+     * @return int
+     */
+    public function isSendingLimitExceeded($customerId)
+    {
+        $config = Mage::getSingleton('enterprise_invitation/config');
+        $sendInterval = $config->getMinInvitationPeriod();
+        $collection = $this->getCollection()
+            ->addFilter('customer_id', $customerId)
+            ->addFieldToFilter('invitation_date', array(
+                'from' => $this->getResource()->formatDate(strtotime("-{$sendInterval} minutes"))
+            ));
+        return count($collection) < $config->getMaxInvitationsPerSend()
+            ? $config->getMaxInvitationsPerSend() - count($collection)
+            : 0;
+    }
 }
diff --git app/code/core/Enterprise/Invitation/controllers/IndexController.php app/code/core/Enterprise/Invitation/controllers/IndexController.php
index 803fa90..b254a58 100644
--- app/code/core/Enterprise/Invitation/controllers/IndexController.php
+++ app/code/core/Enterprise/Invitation/controllers/IndexController.php
@@ -60,53 +60,72 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
     {
         $data = $this->getRequest()->getPost();
         if ($data) {
-            $customer = Mage::getSingleton('customer/session')->getCustomer();
-            $invPerSend = Mage::getSingleton('enterprise_invitation/config')->getMaxInvitationsPerSend();
-            $attempts = 0;
-            $sent     = 0;
+            if (!$this->_validateFormKey()) {
+                return $this->_redirect('*/*/');
+            }
+            $customer       = Mage::getSingleton('customer/session')->getCustomer();
+            $attempts       = 0;
+            $sent           = 0;
             $customerExists = 0;
+            $leftAttempts   = Mage::getModel('enterprise_invitation/invitation')
+                ->isSendingLimitExceeded($customer->getId());
+
+            if (!$leftAttempts) {
+                Mage::getSingleton('customer/session')->addError(
+                    Mage::helper('enterprise_invitation')->__('Invitations limit exceeded. Please try again later.')
+                );
+                $this->_redirect('*/*/*');
+                return;
+            }
             foreach ($data['email'] as $email) {
                 $attempts++;
-                if (!Zend_Validate::is($email, 'EmailAddress')) {
+
+                if ($attempts > $leftAttempts) {
                     continue;
                 }
-                if ($attempts > $invPerSend) {
+
+                if (!Zend_Validate::is($email, 'EmailAddress')) {
                     continue;
                 }
+
                 try {
                     $invitation = Mage::getModel('enterprise_invitation/invitation')->setData(array(
                         'email'    => $email,
                         'customer' => $customer,
-                        'message'  => (isset($data['message']) ? $data['message'] : ''),
+                        'message'  => (isset($data['message'])
+                            ? Mage::helper('core')->escapeHtml($data['message'])
+                            : ''
+                        ),
                     ))->save();
                     if ($invitation->sendInvitationEmail()) {
                         Mage::getSingleton('customer/session')->addSuccess(
-                            Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
+                            Mage::helper('enterprise_invitation')
+                                ->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
                         );
                         $sent++;
-                    }
-                    else {
+                    } else {
                         throw new Exception(''); // not Mage_Core_Exception intentionally
                     }
 
-                }
-                catch (Mage_Core_Exception $e) {
+                } catch (Mage_Core_Exception $e) {
                     if (Enterprise_Invitation_Model_Invitation::ERROR_CUSTOMER_EXISTS === $e->getCode()) {
                         $customerExists++;
-                    }
-                    else {
+                    } else {
                         Mage::getSingleton('customer/session')->addError($e->getMessage());
                     }
-                }
-                catch (Exception $e) {
+                } catch (Exception $e) {
                     Mage::getSingleton('customer/session')->addError(
-                        Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
+                        Mage::helper('enterprise_invitation')
+                            ->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
                     );
                 }
             }
             if ($customerExists) {
                 Mage::getSingleton('customer/session')->addNotice(
-                    Mage::helper('enterprise_invitation')->__('%d invitation(s) were not sent, because customer accounts already exist for specified email addresses.', $customerExists)
+                    Mage::helper('enterprise_invitation')
+                        ->__('%d invitation(s) were not sent, because customer accounts already exist for specified email addresses.',
+                            $customerExists
+                    )
                 );
             }
             $this->_redirect('*/*/');
diff --git app/code/core/Enterprise/Invitation/etc/config.xml app/code/core/Enterprise/Invitation/etc/config.xml
index 2e7fbab..29fe964 100644
--- app/code/core/Enterprise/Invitation/etc/config.xml
+++ app/code/core/Enterprise/Invitation/etc/config.xml
@@ -172,6 +172,7 @@
                 <registration_required_invitation>0</registration_required_invitation>
                 <max_invitation_amount_per_send>5</max_invitation_amount_per_send>
                 <allow_customer_message>1</allow_customer_message>
+                <interval>10</interval>
             </general>
         </enterprise_invitation>
     </default>
diff --git app/code/core/Enterprise/Invitation/etc/system.xml app/code/core/Enterprise/Invitation/etc/system.xml
index 23fcb15..9108eda 100644
--- app/code/core/Enterprise/Invitation/etc/system.xml
+++ app/code/core/Enterprise/Invitation/etc/system.xml
@@ -128,6 +128,14 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
                         </max_invitation_amount_per_send>
+                        <interval translate="label">
+                            <label>Minimum Interval between invites(minutes)</label>
+                            <validate>validate-digits</validate>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </interval>
                     </fields>
                 </general>
             </groups>
diff --git app/code/core/Enterprise/PageCache/Helper/Data.php app/code/core/Enterprise/PageCache/Helper/Data.php
index 83fb29c..89efd5f 100644
--- app/code/core/Enterprise/PageCache/Helper/Data.php
+++ app/code/core/Enterprise/PageCache/Helper/Data.php
@@ -85,4 +85,22 @@ class Enterprise_PageCache_Helper_Data extends Mage_Core_Helper_Abstract
          */
         Enterprise_PageCache_Helper_Form_Key::replaceFormKey($content);
     }
+
+    /**
+     * Check if the request is secure or not
+     *
+     * @return bool
+     */
+    public static function isSSL()
+    {
+        $isSSL           = false;
+        $standardRule    = !empty($_SERVER['HTTPS']) && ('off' != $_SERVER['HTTPS']);
+        $offloaderHeader = Enterprise_PageCache_Model_Cache::getCacheInstance()->load(Enterprise_PageCache_Model_Processor::SSL_OFFLOADER_HEADER_KEY);
+        $offloaderHeader = trim(@unserialize($offloaderHeader));
+
+        if ((!empty($offloaderHeader) && !empty($_SERVER[$offloaderHeader])) || $standardRule) {
+            $isSSL = true;
+        }
+        return $isSSL;
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Helper/Form/Key.php app/code/core/Enterprise/PageCache/Helper/Form/Key.php
index 488734b..076ecee 100644
--- app/code/core/Enterprise/PageCache/Helper/Form/Key.php
+++ app/code/core/Enterprise/PageCache/Helper/Form/Key.php
@@ -76,4 +76,46 @@ class Enterprise_PageCache_Helper_Form_Key extends Mage_Core_Helper_Abstract
         $content = str_replace(self::_getFormKeyMarker(), $formKey, $content, $replacementCount);
         return ($replacementCount > 0);
     }
+
+    /**
+     * Get form key cache id
+     *
+     * @param boolean $renew
+     * @return string
+     */
+    public static function getFormKeyCacheId($renew = false)
+    {
+        $formKeyId = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
+        if ($renew && $formKeyId) {
+            Enterprise_PageCache_Model_Cache::getCacheInstance()->remove(self::getFormKeyCacheId());
+            $formKeyId = false;
+            Mage::unregister('cached_form_key_id');
+        }
+        if (!$formKeyId) {
+            if (!$formKeyId = Mage::registry('cached_form_key_id')) {
+                $formKeyId = Enterprise_PageCache_Helper_Data::getRandomString(16);
+                Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($formKeyId);
+                Mage::register('cached_form_key_id', $formKeyId);
+            }
+        }
+        return $formKeyId;
+    }
+
+    /**
+     * Get cached form key
+     *
+     * @param boolean $renew
+     * @return string
+     */
+    public static function getFormKey($renew = false)
+    {
+        $formKeyId = self::getFormKeyCacheId($renew);
+        $formKey = Enterprise_PageCache_Model_Cache::getCacheInstance()->load($formKeyId);
+        if ($renew) {
+            $formKey = Enterprise_PageCache_Helper_Data::getRandomString(16);
+            Enterprise_PageCache_Model_Cache::getCacheInstance()
+                ->save($formKey, $formKeyId, array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+        }
+        return $formKey;
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Cookie.php app/code/core/Enterprise/PageCache/Model/Cookie.php
index ff2f071..31197c5 100644
--- app/code/core/Enterprise/PageCache/Model/Cookie.php
+++ app/code/core/Enterprise/PageCache/Model/Cookie.php
@@ -38,6 +38,7 @@ class Enterprise_PageCache_Model_Cookie extends Mage_Core_Model_Cookie
      */
     const COOKIE_CUSTOMER           = 'CUSTOMER';
     const COOKIE_CUSTOMER_GROUP     = 'CUSTOMER_INFO';
+    const COOKIE_CUSTOMER_RATES     = 'CUSTOMER_RATES';
 
     const COOKIE_MESSAGE            = 'NEWMESSAGE';
     const COOKIE_CART               = 'CART';
@@ -144,16 +145,35 @@ class Enterprise_PageCache_Model_Cookie extends Mage_Core_Model_Cookie
                 $this->setObscure(self::COOKIE_CUSTOMER_LOGGED_IN, 'customer_logged_in_' . $session->isLoggedIn());
             } else {
                 $this->delete(self::COOKIE_CUSTOMER_LOGGED_IN);
+                $this->delete(self::COOKIE_CUSTOMER_RATES);
             }
         } else {
             $this->delete(self::COOKIE_CUSTOMER);
             $this->delete(self::COOKIE_CUSTOMER_GROUP);
             $this->delete(self::COOKIE_CUSTOMER_LOGGED_IN);
+            $this->delete(self::COOKIE_CUSTOMER_RATES);
         }
         return $this;
     }
 
     /**
+     * Update customer rates cookie
+     */
+    public function updateCustomerRatesCookie()
+    {
+        /** @var $taxConfig Mage_Tax_Model_Config */
+        $taxConfig = Mage::getSingleton('tax/config');
+        if ($taxConfig->getPriceDisplayType() > 1) {
+            /** @var $taxCalculationModel Mage_Tax_Model_Calculation */
+            $taxCalculationModel = Mage::getSingleton('tax/calculation');
+            $request = $taxCalculationModel->getRateRequest();
+            $rates = $taxCalculationModel->getApplicableRateIds($request);
+            sort($rates);
+            $this->setObscure(self::COOKIE_CUSTOMER_RATES, 'customer_rates_' . implode(',', $rates));
+        }
+    }
+
+    /**
      * Register viewed product ids in cookie
      *
      * @param int|string|array $productIds
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index 62adfca..ac58489 100755
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -4,24 +4,24 @@
  *
  * NOTICE OF LICENSE
  *
- * This source file is subject to the Magento Enterprise Edition License
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
  * that is bundled with this package in the file LICENSE_EE.txt.
  * It is also available through the world-wide-web at this URL:
- * http://www.magentocommerce.com/license/enterprise-edition
+ * http://www.magento.com/license/enterprise-edition
  * If you did not receive a copy of the license and are unable to
  * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
+ * to license@magento.com so we can send you a copy immediately.
  *
  * DISCLAIMER
  *
  * Do not edit or add to this file if you wish to upgrade Magento to newer
  * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
+ * needs please refer to http://www.magento.com for more information.
  *
  * @category    Enterprise
  * @package     Enterprise_PageCache
- * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://www.magentocommerce.com/license/enterprise-edition
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
  */
 
 /**
@@ -38,6 +38,16 @@ class Enterprise_PageCache_Model_Observer
      */
     const XML_PATH_DESIGN_EXCEPTION = 'design/package/ua_regexp';
 
+    /*
+     * Theme types exceptions involved into cache key
+     */
+    protected $_themeExceptionTypes = array(
+        'template',
+        'skin',
+        'layout',
+        'default'
+    );
+
     /**
      * Page Cache Processor
      *
@@ -60,6 +70,20 @@ class Enterprise_PageCache_Model_Observer
     protected $_isEnabled;
 
     /**
+     * Cache instance
+     *
+     * @var Mage_Core_Model_Cache
+     */
+    protected $_cacheInstance;
+
+    /**
+     * Uses for store rendering context (parent blocks)
+     *
+     * @var array
+     */
+    protected $_context = array();
+
+    /**
      * Class constructor
      */
     public function __construct(array $args = array())
@@ -69,6 +93,9 @@ class Enterprise_PageCache_Model_Observer
             : Mage::getSingleton('enterprise_pagecache/processor');
         $this->_config = isset($args['config']) ? $args['config'] : Mage::getSingleton('enterprise_pagecache/config');
         $this->_isEnabled = isset($args['enabled']) ? $args['enabled'] : Mage::app()->useCache('full_page');
+        $this->_cacheInstance = isset($args['cacheInstance'])
+            ? $args['cacheInstance']
+            : Enterprise_PageCache_Model_Cache::getCacheInstance();
     }
 
     /**
@@ -96,6 +123,7 @@ class Enterprise_PageCache_Model_Observer
         $request = $frontController->getRequest();
         $response = $frontController->getResponse();
         $this->_saveDesignException();
+        $this->_checkAndSaveSslOffloaderHeaderToCache();
         $this->_processor->processRequestResponse($request, $response);
         return $this;
     }
@@ -124,8 +152,14 @@ class Enterprise_PageCache_Model_Observer
         }
         /**
          * Check if request will be cached
+         * canProcessRequest checks is theoretically possible to cache page
+         * getRequestProcessor check is page have full page cache processor
+         * isStraight works for partially cached pages where getRequestProcessor doesn't work
+         * (not all holes are filled by content)
          */
-        if ($this->_processor->canProcessRequest($request)) {
+        if ($this->_processor->canProcessRequest($request)
+            && ($request->isStraight() || $this->_processor->getRequestProcessor($request))
+        ) {
             Mage::app()->getCacheInstance()->banUse(Mage_Core_Block_Abstract::CACHE_GROUP);
         }
         $this->_getCookie()->updateCustomerCookies();
@@ -133,6 +167,32 @@ class Enterprise_PageCache_Model_Observer
     }
 
     /**
+     * @return array
+     */
+    protected function _loadDesignExceptions()
+    {
+        $exceptions = $this->_cacheInstance
+            ->load(Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY)
+        ;
+        $exceptions = @Zend_Json::decode($exceptions);
+        return is_array($exceptions) ? $exceptions : array();
+    }
+
+    /**
+     * @param array $exceptions
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    protected function _saveDesignExceptions(array $exceptions)
+    {
+        $this->_cacheInstance->save(
+            Zend_Json::encode($exceptions),
+            Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY,
+            array(Enterprise_PageCache_Model_Processor::CACHE_TAG)
+        );
+        return $this;
+    }
+
+    /**
      * Checks whether exists design exception value in cache.
      * If not, gets it from config and puts into cache
      *
@@ -143,18 +203,67 @@ class Enterprise_PageCache_Model_Observer
         if (!$this->isCacheEnabled()) {
             return $this;
         }
-        $cacheId = Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY;
 
-        if (!Enterprise_PageCache_Model_Cache::getCacheInstance()->getFrontend()->test($cacheId)) {
-            $exception = Mage::getStoreConfig(self::XML_PATH_DESIGN_EXCEPTION);
-            Enterprise_PageCache_Model_Cache::getCacheInstance()
-                ->save($exception, $cacheId, array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+        if (isset($_COOKIE[Mage_Core_Model_Store::COOKIE_NAME])) {
+            $storeIdentifier = $_COOKIE[Mage_Core_Model_Store::COOKIE_NAME];
+        } else {
+            $storeIdentifier = Mage::app()->getRequest()->getHttpHost() . Mage::app()->getRequest()->getBaseUrl();
+        }
+        $exceptions = $this->_loadDesignExceptions();
+        if (!isset($exceptions[$storeIdentifier])) {
+            $exceptions[$storeIdentifier][self::XML_PATH_DESIGN_EXCEPTION] = Mage::getStoreConfig(
+                self::XML_PATH_DESIGN_EXCEPTION
+            );
+            foreach ($this->_themeExceptionTypes as $type) {
+                $configPath = sprintf('design/theme/%s_ua_regexp', $type);
+                $exceptions[$storeIdentifier][$configPath] = Mage::getStoreConfig($configPath);
+            }
+            $this->_saveDesignExceptions($exceptions);
             $this->_processor->refreshRequestIds();
         }
         return $this;
     }
 
     /**
+     * Saves 'web/secure/offloader_header' config to cache, only when value was updated
+     *
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    protected function _checkAndSaveSslOffloaderHeaderToCache()
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+        $sslOffloaderHeader = trim((string) Mage::getConfig()->getNode(
+            Mage_Core_Model_Store::XML_PATH_OFFLOADER_HEADER,
+            'default'
+        ));
+
+        $cachedSslOffloaderHeader = $this->_cacheInstance
+            ->load(Enterprise_PageCache_Model_Processor::SSL_OFFLOADER_HEADER_KEY);
+        $cachedSslOffloaderHeader = trim(@Zend_Json::decode($cachedSslOffloaderHeader));
+
+        if ($cachedSslOffloaderHeader != $sslOffloaderHeader) {
+            $this->_saveSslOffloaderHeaderToCache($sslOffloaderHeader);
+        }
+        return $this;
+    }
+
+    /**
+     * Save 'web/secure/offloader_header' config to cache
+     *
+     * @param $value
+     */
+    protected function _saveSslOffloaderHeaderToCache($value)
+    {
+        $this->_cacheInstance->save(
+            Zend_Json::encode($value),
+            Enterprise_PageCache_Model_Processor::SSL_OFFLOADER_HEADER_KEY,
+            array(Enterprise_PageCache_Model_Processor::CACHE_TAG)
+        );
+    }
+
+    /**
      * model_load_after event processor. Collect tags of all loaded entities
      *
      * @param Varien_Event_Observer $observer
@@ -177,6 +286,22 @@ class Enterprise_PageCache_Model_Observer
     }
 
     /**
+     * Add block to rendering context if it declared as cached
+     *
+     * @param Varien_Event_Observer $observer
+     * @return $this
+     */
+    public function registerBlockContext(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+        $block = $observer->getEvent()->getBlock();
+        $this->registerContext($block);
+        return $this;
+    }
+
+    /**
      * Retrieve block tags and add it to processor
      *
      * @param Varien_Event_Observer $observer
@@ -190,9 +315,8 @@ class Enterprise_PageCache_Model_Observer
 
         /** @var $block Mage_Core_Block_Abstract*/
         $block = $observer->getEvent()->getBlock();
-        if (in_array($block->getType(), array_keys($this->_config->getDeclaredPlaceholders()))) {
-            return $this;
-        }
+        $contextBlock = $this->_getContextBlock($block);
+        $this->unregisterContext($block);
 
         $tags = $block->getCacheTags();
         if (empty($tags)) {
@@ -205,12 +329,59 @@ class Enterprise_PageCache_Model_Observer
         if (empty($tags)) {
             return $this;
         }
-        $this->_processor->addRequestTag($tags);
+
+        if (!empty($contextBlock)) {
+            if ($contextBlock->getType() != $block->getType()) {
+                $contextBlock->addCacheTag($tags);
+            } else {
+                $block->addCacheTag($tags);
+            }
+        } else {
+            $this->_processor->addRequestTag($tags);
+        }
 
         return $this;
     }
 
     /**
+     * Retrieve nearest cached block from context
+     *
+     * @return bool|Mage_Core_Block_Abstract
+     */
+    protected function _getContextBlock()
+    {
+        $contextBlock = end($this->_context);
+        reset($this->_context);
+
+        return $contextBlock;
+    }
+
+    /**
+     * Store block to context
+     *
+     * @param Mage_Core_Block_Abstract $block
+     */
+    public function registerContext(Mage_Core_Block_Abstract $block)
+    {
+        if (in_array($block->getType(), array_keys($this->_config->getDeclaredPlaceholders()))) {
+            array_push($this->_context, $block);
+        }
+    }
+
+    /**
+     * Remove last block from context
+     *
+     * @param Mage_Core_Block_Abstract $block
+     */
+    public function unregisterContext(Mage_Core_Block_Abstract $block)
+    {
+        if (in_array($block->getType(), array_keys($this->_config->getDeclaredPlaceholders()))) {
+            array_pop($this->_context);
+        }
+
+    }
+
+    /**
      * Check category state on post dispatch to allow category page be cached
      *
      * @param Varien_Event_Observer $observer
@@ -309,7 +480,18 @@ class Enterprise_PageCache_Model_Observer
      */
     public function cleanCache()
     {
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->clean(Enterprise_PageCache_Model_Processor::CACHE_TAG);
+        $this->_cacheInstance->clean(Enterprise_PageCache_Model_Processor::CACHE_TAG);
+        return $this;
+    }
+
+    /**
+     * Flush full page cache
+     *
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function flushCache()
+    {
+        $this->_cacheInstance->flush();
         return $this;
     }
 
@@ -324,11 +506,11 @@ class Enterprise_PageCache_Model_Observer
         /** @var $tags array */
         $tags = $observer->getEvent()->getTags();
         if (empty($tags)) {
-            Enterprise_PageCache_Model_Cache::getCacheInstance()->clean();
+            $this->_cacheInstance->clean();
             return $this;
         }
 
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->clean($tags);
+        $this->_cacheInstance->clean($tags);
         return $this;
     }
 
@@ -338,7 +520,7 @@ class Enterprise_PageCache_Model_Observer
      */
     public function cleanExpiredCache()
     {
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->getFrontend()->clean(Zend_Cache::CLEANING_MODE_OLD);
+        $this->_cacheInstance->getFrontend()->clean(Zend_Cache::CLEANING_MODE_OLD);
         return $this;
     }
 
@@ -375,7 +557,10 @@ class Enterprise_PageCache_Model_Observer
             $processor = $this->_processor->getRequestProcessor($request);
             if ($processor && $processor->allowCache($request)) {
                 $container = $placeholder->getContainerClass();
-                if ($container && !Mage::getIsDeveloperMode()) {
+                if ($container
+                    && !Mage::getIsDeveloperMode()
+                    && class_exists($container)
+                ) {
                     $container = new $container($placeholder);
                     $container->setProcessor(Mage::getSingleton('enterprise_pagecache/processor'));
                     $container->setPlaceholderBlock($block);
@@ -426,7 +611,7 @@ class Enterprise_PageCache_Model_Observer
         $this->_getCookie()->setObscure(Enterprise_PageCache_Model_Cookie::COOKIE_CART, 'quote_' . $quote->getId());
 
         $cacheId = Enterprise_PageCache_Model_Container_Advanced_Quote::getCacheId();
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->remove($cacheId);
+        $this->_cacheInstance->remove($cacheId);
 
         return $this;
     }
@@ -525,6 +710,23 @@ class Enterprise_PageCache_Model_Observer
     }
 
     /**
+     * Update customer rates cookie after address update
+     *
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function customerAddressUpdate(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+        $cookie = $this->_getCookie();
+        $cookie->updateCustomerCookies();
+        $cookie->updateCustomerRatesCookie();
+        return $this;
+    }
+
+    /**
      * Set cookie for logged in customer
      *
      * @param Varien_Event_Observer $observer
@@ -535,8 +737,11 @@ class Enterprise_PageCache_Model_Observer
         if (!$this->isCacheEnabled()) {
             return $this;
         }
-        $this->_getCookie()->updateCustomerCookies();
+        $cookie = $this->_getCookie();
+        $cookie->updateCustomerCookies();
+        $cookie->updateCustomerRatesCookie();
         $this->updateCustomerProductIndex();
+        $this->updateFormKeyCookie();
         return $this;
     }
 
@@ -559,6 +764,7 @@ class Enterprise_PageCache_Model_Observer
             Enterprise_PageCache_Model_Cookie::registerViewedProducts(array(), 0, false);
         }
 
+        $this->updateFormKeyCookie();
         return $this;
     }
 
@@ -586,7 +792,7 @@ class Enterprise_PageCache_Model_Observer
         $this->_getCookie()->setObscure(Enterprise_PageCache_Model_Cookie::COOKIE_WISHLIST_ITEMS,
             'wishlist_item_count_' . Mage::helper('wishlist')->getItemCount());
 
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->clean(
+        $this->_cacheInstance->clean(
             Mage::helper('wishlist')->getWishlist()->getCacheIdTags()
         );
 
@@ -605,7 +811,7 @@ class Enterprise_PageCache_Model_Observer
             return $this;
         }
 
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->clean(
+        $this->_cacheInstance->clean(
             $observer->getEvent()->getWishlist()->getCacheIdTags()
         );
     }
@@ -623,7 +829,7 @@ class Enterprise_PageCache_Model_Observer
         }
 
         $blockContainer = Mage::getModel('enterprise_pagecache/container_wishlists');
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->remove($blockContainer->getCacheId());
+        $this->_cacheInstance->remove($blockContainer->getCacheId());
 
         return $this;
     }
@@ -660,7 +866,7 @@ class Enterprise_PageCache_Model_Observer
 
         /** @var $blockContainer Enterprise_PageCache_Model_Container_Orders */
         $blockContainer = Mage::getModel('enterprise_pagecache/container_orders');
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->remove($blockContainer->getCacheId());
+        $this->_cacheInstance->remove($blockContainer->getCacheId());
         return $this;
     }
 
@@ -687,10 +893,27 @@ class Enterprise_PageCache_Model_Observer
      */
     public function registerDesignExceptionsChange(Varien_Event_Observer $observer)
     {
-        $object = $observer->getDataObject();
-        Enterprise_PageCache_Model_Cache::getCacheInstance()
-            ->save($object->getValue(), Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY,
-                array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+        $this->_cacheInstance
+            ->remove(Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY);
+        return $this;
+    }
+
+    /**
+     * Re-save exception rules to cache storage
+     *
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function registerSslOffloaderChange(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+
+        $object = $observer->getEvent()->getDataObject();
+        if ($object) {
+            $this->_saveSslOffloaderHeaderToCache($object->getValue());
+        }
         return $this;
     }
 
@@ -800,7 +1023,7 @@ class Enterprise_PageCache_Model_Observer
         if ($category->isObjectNew() ||
             ($category->dataHasChangedFor('is_active') || $category->dataHasChangedFor('include_in_menu'))
         ) {
-            Enterprise_PageCache_Model_Cache::getCacheInstance()->clean(Mage_Catalog_Model_Category::CACHE_TAG);
+            $this->_cacheInstance->clean(Mage_Catalog_Model_Category::CACHE_TAG);
         }
     }
 
@@ -818,8 +1041,57 @@ class Enterprise_PageCache_Model_Observer
         /** @var $session Mage_Core_Model_Session  */
         $session = Mage::getSingleton('core/session');
         $cachedFrontFormKey = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
-        if ($cachedFrontFormKey) {
-            $session->setData('_form_key', $cachedFrontFormKey);
+        if ($cachedFrontFormKey && !$session->getData('_form_key')) {
+            Mage::getSingleton('core/session')->setData('_form_key', $cachedFrontFormKey);
+        }
+    }
+
+    /**
+     * Clean cached tags for product on saving review
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function registerReviewSave(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return;
+        }
+
+        $review = $observer->getEvent()->getDataObject();
+        $product = Mage::getModel('catalog/product')->load($review->getEntityPkValue());
+        if ($product->getId() && $this->_isChangedReviewVisibility($review)) {
+            $this->_cacheInstance->clean($product->getCacheTags());
+        }
+    }
+
+    /**
+     * Check is review visibility was changed
+     *
+     * @param Mage_Review_Model_Review $review
+     * @return bool
+     */
+    protected function _isChangedReviewVisibility($review)
+    {
+        return $review->getData('status_id') == Mage_Review_Model_Review::STATUS_APPROVED
+            || ($review->getData('status_id') != Mage_Review_Model_Review::STATUS_APPROVED
+            && $review->getOrigData('status_id') == Mage_Review_Model_Review::STATUS_APPROVED);
+    }
+
+    /**
+     * Clean cached tags for product on deleting review
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function registerReviewDelete(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return;
+        }
+
+        $review = $observer->getEvent()->getDataObject();
+        $product = Mage::getModel('catalog/product')->load($review->getOrigData('entity_pk_value'));
+        if ($product->getId() && $review->getOrigData('status_id') == Mage_Review_Model_Review::STATUS_APPROVED) {
+            $this->_cacheInstance->clean($product->getCacheTags());
         }
     }
 
@@ -841,7 +1113,7 @@ class Enterprise_PageCache_Model_Observer
 
         /** @var $product Mage_Catalog_Model_Product */
         foreach ($productCollection as $product) {
-            Enterprise_PageCache_Model_Cache::getCacheInstance()->clean($product->getCacheTags());
+            $this->_cacheInstance->clean($product->getCacheTags());
         }
     }
 
@@ -858,7 +1130,7 @@ class Enterprise_PageCache_Model_Observer
             return $this;
         }
         $redirect = $observer->getEvent()->getRedirect();
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->clean(
+        $this->_cacheInstance->clean(
             array(
                 Enterprise_PageCache_Helper_Url::prepareRequestPathTag($redirect->getData('identifier')),
                 Enterprise_PageCache_Helper_Url::prepareRequestPathTag($redirect->getData('target_path')),
@@ -868,4 +1140,29 @@ class Enterprise_PageCache_Model_Observer
         );
         return $this;
     }
+
+    /**
+     * Clear request path cache by tag
+     * (used for redirects invalidation)
+     *
+     * @param Varien_Event_Observer $observer
+     * @return $this
+     */
+    public function fixInvalidCategoryCookie(Varien_Event_Observer $observer)
+    {
+        $categoryId = $observer->getCategoryId();
+        if (Enterprise_PageCache_Model_Cookie::getCategoryCookieValue () != $categoryId) {
+            Enterprise_PageCache_Model_Cookie::setCategoryViewedCookieValue($categoryId);
+            Enterprise_PageCache_Model_Cookie::setCurrentCategoryCookieValue($categoryId);
+        }
+
+    }
+
+    /**
+     * Updates form key cookie with hash from session
+     */
+    public function updateFormKeyCookie()
+    {
+        Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue(Mage::getSingleton('core/session')->getFormKey());
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index fae567a..b81b5ea 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -40,6 +40,7 @@ class Enterprise_PageCache_Model_Processor
     const DESIGN_EXCEPTION_KEY          = 'FPC_DESIGN_EXCEPTION_CACHE';
     const DESIGN_CHANGE_CACHE_SUFFIX    = 'FPC_DESIGN_CHANGE_CACHE';
     const CACHE_SIZE_KEY                = 'FPC_CACHE_SIZE_CAHCE_KEY';
+    const SSL_OFFLOADER_HEADER_KEY      = 'FPC_SSL_OFFLOADER_HEADER_CACHE';
     const XML_PATH_CACHE_MAX_SIZE       = 'system/page_cache/max_cache_size';
     const REQUEST_PATH_PREFIX           = 'REQUEST_PATH_';
 
@@ -143,6 +144,9 @@ class Enterprise_PageCache_Model_Processor
             if (isset($_COOKIE[Enterprise_PageCache_Model_Cookie::IS_USER_ALLOWED_SAVE_COOKIE])) {
                 $uri .= '_' . $_COOKIE[Enterprise_PageCache_Model_Cookie::IS_USER_ALLOWED_SAVE_COOKIE];
             }
+            if (Enterprise_PageCache_Helper_Data::isSSL()) {
+                $uri .= '_ssl';
+            }
             $designPackage = $this->_getDesignPackage();
 
             if ($designPackage) {
diff --git app/code/core/Enterprise/PageCache/Model/Processor/Category.php app/code/core/Enterprise/PageCache/Model/Processor/Category.php
index 3be8db8..82fd2b6 100644
--- app/code/core/Enterprise/PageCache/Model/Processor/Category.php
+++ app/code/core/Enterprise/PageCache/Model/Processor/Category.php
@@ -63,8 +63,9 @@ class Enterprise_PageCache_Model_Processor_Category extends Enterprise_PageCache
             $processor->setMetadata(self::METADATA_CATEGORY_ID, $category->getId());
             $this->_updateCategoryViewedCookie($processor);
         }
+        $pageId = $processor->getRequestId() . '_' . md5($queryParams);
 
-        return $processor->getRequestId() . '_' . md5($queryParams);
+        return $this->_appendCustomerRatesToPageId($pageId);
     }
 
     /**
@@ -92,7 +93,9 @@ class Enterprise_PageCache_Model_Processor_Category extends Enterprise_PageCache
 
         Enterprise_PageCache_Model_Cookie::setCategoryCookieValue($queryParams);
 
-        return $processor->getRequestId() . '_' . md5($queryParams);
+        $pageId = $processor->getRequestId() . '_' . md5($queryParams);
+
+        return $this->_appendCustomerRatesToPageId($pageId);
     }
 
     /**
diff --git app/code/core/Enterprise/PageCache/Model/Processor/Default.php app/code/core/Enterprise/PageCache/Model/Processor/Default.php
index 95ec63f..3d23aca 100644
--- app/code/core/Enterprise/PageCache/Model/Processor/Default.php
+++ app/code/core/Enterprise/PageCache/Model/Processor/Default.php
@@ -151,6 +151,20 @@ class Enterprise_PageCache_Model_Processor_Default
     }
 
     /**
+     * Append customer rates cookie to page id
+     *
+     * @param string $pageId
+     * @return string
+     */
+    protected function _appendCustomerRatesToPageId($pageId)
+    {
+        if (isset($_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_CUSTOMER_RATES])) {
+            $pageId .= '_' . $_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_CUSTOMER_RATES];
+        }
+        return $pageId;
+    }
+
+    /**
      * Get request uri based on HTTP request uri and visitor session state
      *
      * @deprecated after 1.8
diff --git app/code/core/Enterprise/PageCache/Model/Processor/Product.php app/code/core/Enterprise/PageCache/Model/Processor/Product.php
index eb1dd01..1d933b7 100644
--- app/code/core/Enterprise/PageCache/Model/Processor/Product.php
+++ app/code/core/Enterprise/PageCache/Model/Processor/Product.php
@@ -63,4 +63,16 @@ class Enterprise_PageCache_Model_Processor_Product extends Enterprise_PageCache_
 
         return parent::prepareContent($response);
     }
+
+    /**
+     * Return cache page id without application. Depends on GET super global array.
+     *
+     * @param Enterprise_PageCache_Model_Processor $processor
+     * @return string
+     */
+    public function getPageIdWithoutApp(Enterprise_PageCache_Model_Processor $processor)
+    {
+        $pageId = parent::getPageIdWithoutApp($processor);
+        return $this->_appendCustomerRatesToPageId($pageId);
+    }
 }
diff --git app/code/core/Enterprise/PageCache/etc/config.xml app/code/core/Enterprise/PageCache/etc/config.xml
index a71fc71..b94475c 100644
--- app/code/core/Enterprise/PageCache/etc/config.xml
+++ app/code/core/Enterprise/PageCache/etc/config.xml
@@ -367,6 +367,14 @@
                     </enterprise_pagecache>
                 </observers>
             </core_config_backend_design_exception_save_after>
+            <core_config_backend_web_secure_offloaderheader_save_after>
+                <observers>
+                    <enterprise_pagecache>
+                        <class>enterprise_pagecache/observer</class>
+                        <method>registerSslOffloaderChange</method>
+                    </enterprise_pagecache>
+                </observers>
+            </core_config_backend_web_secure_offloaderheader_save_after>
             <core_config_matcher_priority_save_after>
                 <observers>
                     <enterprise_pagecache>
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 8d0d0b9..b4dc0c9 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -138,6 +138,9 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
                 Mage::throwException(Mage::helper('adminhtml')->__('Invalid User Name or Password.'));
             }
         } catch (Mage_Core_Exception $e) {
+            $e->setMessage(
+                Mage::helper('adminhtml')->__('You did not sign in correctly or your account is temporarily disabled.')
+            );
             Mage::dispatchEvent('admin_session_user_login_failed',
                 array('user_name' => $username, 'exception' => $e));
             if ($request && !$request->getParam('messageSent')) {
diff --git app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
new file mode 100644
index 0000000..b5f16b8
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+/**
+ * Class Mage_Adminhtml_Block_Checkout_Formkey
+ */
+class Mage_Adminhtml_Block_Checkout_Formkey extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * Check form key validation on checkout.
+     * If disabled, show notice.
+     *
+     * @return boolean
+     */
+    public function canShow()
+    {
+        return !Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
+
+    /**
+     * Get url for edit Advanced -> Admin section
+     *
+     * @return string
+     */
+    public function getSecurityAdminUrl()
+    {
+        return Mage::helper("adminhtml")->getUrl('adminhtml/system_config/edit/section/admin');
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
new file mode 100644
index 0000000..7749411
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
@@ -0,0 +1,36 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+class Mage_Adminhtml_Block_Notification_Symlink extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * @return bool
+     */
+    public function isSymlinkEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_PATH_TEMPLATE_ALLOW_SYMLINK);
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
index ea59b2d..47802a3 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
@@ -146,11 +146,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Date
         if (isset($value['locale'])) {
             if (!empty($value['from'])) {
                 $value['orig_from'] = $value['from'];
-                $value['from'] = $this->_convertDate($value['from'], $value['locale']);
+                $value['from'] = $this->_convertDate($this->stripTags($value['from']), $value['locale']);
             }
             if (!empty($value['to'])) {
                 $value['orig_to'] = $value['to'];
-                $value['to'] = $this->_convertDate($value['to'], $value['locale']);
+                $value['to'] = $this->_convertDate($this->stripTags($value['to']), $value['locale']);
             }
         }
         if (empty($value['from']) && empty($value['to'])) {
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 271e485..431ca46 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -167,6 +167,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
                 if (is_object($fieldConfig)) {
                     $configPath = (string)$fieldConfig->config_path;
                     if (!empty($configPath) && strrpos($configPath, '/') > 0) {
+                        if (!Mage::getSingleton('admin/session')->isAllowed($configPath)) {
+                            Mage::throwException('Access denied.');
+                        }
                         // Extend old data with specified section group
                         $groupPath = substr($configPath, 0, strrpos($configPath, '/'));
                         if (!isset($oldConfigAdditionalGroups[$groupPath])) {
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Web/Secure/Offloaderheader.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Web/Secure/Offloaderheader.php
new file mode 100644
index 0000000..3778af7
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Web/Secure/Offloaderheader.php
@@ -0,0 +1,29 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+class Mage_Adminhtml_Model_System_Config_Backend_Web_Secure_Offloaderheader extends Mage_Core_Model_Config_Data
+{
+    protected $_eventPrefix = 'core_config_backend_web_secure_offloaderheader';
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
index 6a8366d..ac2ae97 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
@@ -42,6 +42,11 @@ class Mage_Adminhtml_Catalog_Product_GalleryController extends Mage_Adminhtml_Co
                 Mage::helper('catalog/image'), 'validateUploadFile');
             $uploader->setAllowRenameFiles(true);
             $uploader->setFilesDispersion(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $result = $uploader->save(
                 Mage::getSingleton('catalog/product_media_config')->getBaseTmpMediaPath()
             );
diff --git app/code/core/Mage/Checkout/controllers/MultishippingController.php app/code/core/Mage/Checkout/controllers/MultishippingController.php
index 3272d35..1143265 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -233,6 +233,12 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             $this->_redirect('*/multishipping_address/newShipping');
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/addresses');
+            return;
+        }
+
         try {
             if ($this->getRequest()->getParam('continue', false)) {
                 $this->_getCheckout()->setCollectRatesFlag(true);
@@ -353,6 +359,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
      */
     public function shippingPostAction()
     {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/shipping');
+            return;
+        }
+
         $shippingMethods = $this->getRequest()->getPost('shipping_method');
         try {
             Mage::dispatchEvent(
@@ -439,6 +450,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             return $this;
         }
 
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/billing');
+            return;
+        }
+
         $this->_getState()->setActiveStep(Mage_Checkout_Model_Type_Multishipping_State::STEP_OVERVIEW);
 
         try {
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 2e3334d..397c1d9 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -350,6 +350,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $method = $this->getRequest()->getPost('method');
             $result = $this->getOnepage()->saveCheckoutMethod($method);
@@ -365,6 +370,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('billing', array());
             $customerAddressId = $this->getRequest()->getPost('billing_address_id', false);
@@ -407,6 +417,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping', array());
             $customerAddressId = $this->getRequest()->getPost('shipping_address_id', false);
@@ -431,6 +446,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping_method', '');
             $result = $this->getOnepage()->saveShippingMethod($data);
@@ -465,6 +485,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         try {
             if (!$this->getRequest()->isPost()) {
                 $this->_ajaxRedirectResponse();
diff --git app/code/core/Mage/Checkout/etc/system.xml app/code/core/Mage/Checkout/etc/system.xml
index 0874790..7650670 100644
--- app/code/core/Mage/Checkout/etc/system.xml
+++ app/code/core/Mage/Checkout/etc/system.xml
@@ -232,5 +232,23 @@
                 </payment_failed>
             </groups>
         </checkout>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <validate_formkey_checkout translate="label comment">
+                            <label>Enable Form Key Validation On Checkout</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>4</sort_order>
+                            <comment><![CDATA[<strong style="color:red">Important!</strong> Enabling this option means
+                            that your custom templates used in checkout process contain form_key output.
+                            Otherwise checkout may not work.]]></comment>
+                            <show_in_default>1</show_in_default>
+                        </validate_formkey_checkout>
+                    </fields>
+                </security>
+            </groups>
+        </admin>
     </sections>
 </config>
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 19b3f45..a4395d8 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -282,6 +282,11 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         }
         $uploader->setAllowRenameFiles(true);
         $uploader->setFilesDispersion(false);
+        $uploader->addValidateCallback(
+            Mage_Core_Model_File_Validator_Image::NAME,
+            Mage::getModel('core/file_validator_image'),
+            'validate'
+        );
         $result = $uploader->save($targetPath);
 
         if (!$result) {
diff --git app/code/core/Mage/Core/Controller/Front/Action.php app/code/core/Mage/Core/Controller/Front/Action.php
index b751f15..102a195 100755
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -4,24 +4,24 @@
  *
  * NOTICE OF LICENSE
  *
- * This source file is subject to the Magento Enterprise Edition License
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
  * that is bundled with this package in the file LICENSE_EE.txt.
  * It is also available through the world-wide-web at this URL:
- * http://www.magentocommerce.com/license/enterprise-edition
+ * http://www.magento.com/license/enterprise-edition
  * If you did not receive a copy of the license and are unable to
  * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
+ * to license@magento.com so we can send you a copy immediately.
  *
  * DISCLAIMER
  *
  * Do not edit or add to this file if you wish to upgrade Magento to newer
  * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
+ * needs please refer to http://www.magento.com for more information.
  *
  * @category    Mage
  * @package     Mage_Core
- * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://www.magentocommerce.com/license/enterprise-edition
+ * @copyright Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
  */
 
 
@@ -39,6 +39,11 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
     const SESSION_NAMESPACE = 'frontend';
 
     /**
+     * Add secret key to url config path
+     */
+    const XML_CSRF_USE_FLAG_CONFIG_PATH   = 'system/csrf/use_form_key';
+
+    /**
      * Currently used area
      *
      * @var string
@@ -159,4 +164,38 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
         }
         return $this;
     }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    protected function _validateFormKey()
+    {
+        $validated = true;
+        if ($this->_isFormKeyEnabled()) {
+            $validated = parent::_validateFormKey();
+        }
+        return $validated;
+    }
+
+    /**
+     * Check if form key validation is enabled.
+     *
+     * @return bool
+     */
+    protected function _isFormKeyEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH);
+    }
+
+    /**
+     * Check if form_key validation enabled on checkout process
+     *
+     * @return bool
+     */
+    protected function isFormkeyValidationOnCheckoutEnabled()
+    {
+        return Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index 6dddd49..512440f 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -148,7 +148,10 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
             $baseUrl = $this->getBaseUrl();
             $pathInfo = substr($requestUri, strlen($baseUrl));
 
-            if ((null !== $baseUrl) && (false === $pathInfo)) {
+            if ($baseUrl && $pathInfo && (0 !== stripos($pathInfo, '/'))) {
+                $pathInfo = '';
+                $this->setActionName('noRoute');
+            } elseif ((null !== $baseUrl) && (false === $pathInfo)) {
                 $pathInfo = '';
             } elseif (null === $baseUrl) {
                 $pathInfo = $requestUri;
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index 554f55d..2abaab9 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -87,10 +87,33 @@ class Mage_Core_Model_File_Validator_Image
      */
     public function validate($filePath)
     {
-        $fileInfo = getimagesize($filePath);
-        if (is_array($fileInfo) and isset($fileInfo[2])) {
-            if ($this->isImageType($fileInfo[2])) {
-                return null;
+        list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
+        if ($fileType) {
+            if ($this->isImageType($fileType)) {
+                //replace tmp image with re-sampled copy to exclude images with malicious data
+                $image = imagecreatefromstring(file_get_contents($filePath));
+                if ($image !== false) {
+                    $img = imagecreatetruecolor($imageWidth, $imageHeight);
+                    imagecopyresampled($img, $image, 0, 0, 0, 0, $imageWidth, $imageHeight, $imageWidth, $imageHeight);
+                    switch ($fileType) {
+                        case IMAGETYPE_GIF:
+                            imagegif($img, $filePath);
+                            break;
+                        case IMAGETYPE_JPEG:
+                            imagejpeg($img, $filePath, 100);
+                            break;
+                        case IMAGETYPE_PNG:
+                            imagepng($img, $filePath);
+                            break;
+                        default:
+                            return;
+                    }
+                    imagedestroy($img);
+                    imagedestroy($image);
+                    return null;
+                } else {
+                    throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid image.'));
+                }
             }
         }
         throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid MIME type.'));
@@ -105,5 +128,4 @@ class Mage_Core_Model_File_Validator_Image
     {
         return in_array($nImageType, $this->_allowedImageTypes);
     }
-
 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 9e9f92a..ed446d0 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -274,6 +274,9 @@
             </js>
         </dev>
         <system>
+            <csrf>
+                <use_form_key>1</use_form_key>
+            </csrf>
             <smtp>
                 <disable>0</disable>
                 <host>localhost</host>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index d945d83..1aa988b 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -529,26 +529,6 @@
                         </template_hints_blocks>
                     </fields>
                 </debug>
-                <template translate="label">
-                    <label>Template Settings</label>
-                    <frontend_type>text</frontend_type>
-                    <sort_order>25</sort_order>
-                    <show_in_default>1</show_in_default>
-                    <show_in_website>1</show_in_website>
-                    <show_in_store>1</show_in_store>
-                    <fields>
-                        <allow_symlink translate="label comment">
-                            <label>Allow Symlinks</label>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>10</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>1</show_in_store>
-                            <comment>Warning! Enabling this feature is not recommended on production environments because it represents a potential security risk.</comment>
-                        </allow_symlink>
-                    </fields>
-                </template>
                 <translate_inline translate="label">
                     <label>Translate Inline</label>
                     <frontend_type>text</frontend_type>
@@ -819,6 +799,25 @@
             <show_in_website>1</show_in_website>
             <show_in_store>1</show_in_store>
             <groups>
+                <csrf translate="label" module="core">
+                    <label>CSRF protection</label>
+                    <frontend_type>text</frontend_type>
+                    <sort_order>0</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>1</show_in_website>
+                    <show_in_store>1</show_in_store>
+                    <fields>
+                        <use_form_key translate="label">
+                            <label>Add Secret Key To Url</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </use_form_key>
+                    </fields>
+                </csrf>
                 <smtp translate="label">
                     <label>Mail Sending Settings</label>
                     <frontend_type>text</frontend_type>
@@ -1336,6 +1335,7 @@
                         <offloader_header translate="label">
                             <label>Offloader header</label>
                             <frontend_type>text</frontend_type>
+                            <backend_model>adminhtml/system_config_backend_web_secure_offloaderheader</backend_model>
                             <sort_order>75</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>0</show_in_website>
diff --git app/code/core/Mage/Customer/Model/Session.php app/code/core/Mage/Customer/Model/Session.php
index 8bf124a..9cae8d2 100644
--- app/code/core/Mage/Customer/Model/Session.php
+++ app/code/core/Mage/Customer/Model/Session.php
@@ -222,6 +222,8 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     public function setCustomerAsLoggedIn($customer)
     {
         $this->setCustomer($customer);
+        $this->renewSession();
+        Mage::getSingleton('core/session')->renewFormKey();
         Mage::dispatchEvent('customer_login', array('customer'=>$customer));
         return $this;
     }
@@ -307,6 +309,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
         $this->setId(null);
         $this->setCustomerGroupId(Mage_Customer_Model_Group::NOT_LOGGED_IN_ID);
         $this->getCookie()->delete($this->getSessionName());
+        Mage::getSingleton('core/session')->renewFormKey();
         return $this;
     }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
index bff4d15..3455701 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
@@ -40,6 +40,9 @@ class Mage_Dataflow_Model_Convert_Adapter_Zend_Cache extends Mage_Dataflow_Model
         if (!$this->_resource) {
             $this->_resource = Zend_Cache::factory($this->getVar('frontend', 'Core'), $this->getVar('backend', 'File'));
         }
+        if ($this->_resource->getBackend() instanceof Zend_Cache_Backend_Static) {
+            throw new Exception(Mage::helper('dataflow')->__('Backend name "Static" not supported.'));
+        }
         return $this->_resource;
     }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index 0afc137..030b665 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -47,6 +47,18 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
     protected $_position;
 
+    /**
+     * Detect serialization of data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    protected function isSerialized($data)
+    {
+        $pattern = '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{s:\d+:\"/';
+        return (is_string($data) && preg_match($pattern, $data));
+    }
+
     public function getVar($key, $default=null)
     {
         if (!isset($this->_vars[$key]) || (!is_array($this->_vars[$key]) && strlen($this->_vars[$key]) == 0)) {
@@ -102,13 +114,45 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
     public function setData($data)
     {
-        if ($this->getProfile()) {
-            $this->getProfile()->getContainer()->setData($data);
+        if ($this->validateDataSerialized($data)) {
+            if ($this->getProfile()) {
+                $this->getProfile()->getContainer()->setData($data);
+            }
+
+            $this->_data = $data;
         }
-        $this->_data = $data;
+
         return $this;
     }
 
+    /**
+     * Validate serialized data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    public function validateDataSerialized($data = null)
+    {
+        if (is_null($data)) {
+            $data = $this->getData();
+        }
+
+        $result = true;
+        if ($this->isSerialized($data)) {
+            try {
+                $dataArray = Mage::helper('core/unserializeArray')->unserialize($data);
+            } catch (Exception $e) {
+                $result = false;
+                $this->addException(
+                    "Invalid data, expecting serialized array.",
+                    Mage_Dataflow_Model_Convert_Exception::FATAL
+                );
+            }
+        }
+
+        return $result;
+    }
+
     public function validateDataString($data=null)
     {
         if (is_null($data)) {
@@ -140,7 +184,10 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
             if (count($data)==0) {
                 return true;
             }
-            $this->addException("Invalid data type, expecting 2D grid array.", Mage_Dataflow_Model_Convert_Exception::FATAL);
+            $this->addException(
+                "Invalid data type, expecting 2D grid array.",
+                Mage_Dataflow_Model_Convert_Exception::FATAL
+            );
         }
         return true;
     }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index a349329..a5fcdc9 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -62,13 +62,15 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
             $adapter = Mage::getModel($adapterName);
         }
         catch (Exception $e) {
-            $message = Mage::helper('dataflow')->__('Declared adapter %s was not found.', $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Declared adapter %s was not found.', $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
 
         if (!method_exists($adapter, $adapterMethod)) {
-            $message = Mage::helper('dataflow')->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
@@ -77,8 +79,8 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index 9e01a11..6f410be 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -69,7 +69,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         }
 
         if (!method_exists($adapter, $adapterMethod)) {
-            $message = Mage::helper('dataflow')->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
@@ -78,8 +79,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/ImportExport/Model/Import/Uploader.php app/code/core/Mage/ImportExport/Model/Import/Uploader.php
index 2c740b4..6396072 100644
--- app/code/core/Mage/ImportExport/Model/Import/Uploader.php
+++ app/code/core/Mage/ImportExport/Model/Import/Uploader.php
@@ -61,6 +61,11 @@ class Mage_ImportExport_Model_Import_Uploader extends Mage_Core_Model_File_Uploa
         $this->setAllowedExtensions(array_keys($this->_allowedMimeTypes));
         $this->addValidateCallback('catalog_product_image',
                 Mage::helper('catalog/image'), 'validateUploadFile');
+        $this->addValidateCallback(
+            Mage_Core_Model_File_Validator_Image::NAME,
+            Mage::getModel('core/file_validator_image'),
+            'validate'
+        );
         $this->_uploadType = self::SINGLE_STYLE;
     }
 
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index 1bae571..09ff0df 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -498,8 +498,9 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
                         /** @var Unserialize_Parser $parser */
                         $parser = Mage::helper('core/unserializeArray');
 
-                        $_itemOptionValue = $parser->unserialize($itemOptionValue);
-                        $_optionValue = $parser->unserialize($optionValue);
+                        $_itemOptionValue =
+                            is_numeric($itemOptionValue) ? $itemOptionValue : $parser->unserialize($itemOptionValue);
+                        $_optionValue = is_numeric($optionValue) ? $optionValue : $parser->unserialize($optionValue);
 
                         if (is_array($_itemOptionValue) && is_array($_optionValue)) {
                             $itemOptionValue = $_itemOptionValue;
diff --git app/code/core/Mage/Tax/Model/Calculation.php app/code/core/Mage/Tax/Model/Calculation.php
index 62bcbe7..f29ec9e 100644
--- app/code/core/Mage/Tax/Model/Calculation.php
+++ app/code/core/Mage/Tax/Model/Calculation.php
@@ -554,6 +554,17 @@ class Mage_Tax_Model_Calculation extends Mage_Core_Model_Abstract
     }
 
     /**
+     * Get rate ids applicable for some address
+     *
+     * @param Varien_Object $request
+     * @return array
+     */
+    public function getApplicableRateIds($request)
+    {
+        return $this->_getResource()->getApplicableRateIds($request);
+    }
+
+    /**
      * Get the calculation process
      *
      * @param array $rates
diff --git app/code/core/Mage/Tax/Model/Resource/Calculation.php app/code/core/Mage/Tax/Model/Resource/Calculation.php
index f822807..f88245d 100755
--- app/code/core/Mage/Tax/Model/Resource/Calculation.php
+++ app/code/core/Mage/Tax/Model/Resource/Calculation.php
@@ -362,6 +362,35 @@ class Mage_Tax_Model_Resource_Calculation extends Mage_Core_Model_Resource_Db_Ab
     }
 
     /**
+     * Get rate ids applicable for some address
+     *
+     * @param Varien_Object $request
+     * @return array
+     */
+    function getApplicableRateIds($request)
+    {
+        $countryId = $request->getCountryId();
+        $regionId = $request->getRegionId();
+        $postcode = $request->getPostcode();
+
+        $select = $this->_getReadAdapter()->select()
+            ->from(array('rate' => $this->getTable('tax/tax_calculation_rate')), array('tax_calculation_rate_id'))
+            ->where('rate.tax_country_id = ?', $countryId)
+            ->where("rate.tax_region_id IN(?)", array(0, (int)$regionId));
+
+        $expr = $this->_getWriteAdapter()->getCheckSql(
+            'zip_is_range is NULL',
+            $this->_getWriteAdapter()->quoteInto(
+                "rate.tax_postcode IS NULL OR rate.tax_postcode IN('*', '', ?)",
+                $this->_createSearchPostCodeTemplates($postcode)
+            ),
+            $this->_getWriteAdapter()->quoteInto('? BETWEEN rate.zip_from AND rate.zip_to', $postcode)
+        );
+        $select->where($expr);
+        return $this->_getReadAdapter()->fetchCol($select);
+    }
+
+    /**
      * Calculate rate
      *
      * @param array $rates
diff --git app/code/core/Mage/Widget/Model/Widget/Instance.php app/code/core/Mage/Widget/Model/Widget/Instance.php
index 6a09b2c..86bde2c 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -347,7 +347,11 @@ class Mage_Widget_Model_Widget_Instance extends Mage_Core_Model_Abstract
     public function getWidgetParameters()
     {
         if (is_string($this->getData('widget_parameters'))) {
-            return unserialize($this->getData('widget_parameters'));
+            try {
+                return Mage::helper('core/unserializeArray')->unserialize($this->getData('widget_parameters'));
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         return (is_array($this->getData('widget_parameters'))) ? $this->getData('widget_parameters') : array();
     }
diff --git app/code/core/Mage/XmlConnect/Helper/Image.php app/code/core/Mage/XmlConnect/Helper/Image.php
index 744fe5e..cfabf51 100644
--- app/code/core/Mage/XmlConnect/Helper/Image.php
+++ app/code/core/Mage/XmlConnect/Helper/Image.php
@@ -100,6 +100,11 @@ class Mage_XmlConnect_Helper_Image extends Mage_Core_Helper_Abstract
             $uploader = Mage::getModel('core/file_uploader', $field);
             $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
             $uploader->setAllowRenameFiles(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $uploader->save($uploadDir);
             $uploadedFilename = $uploader->getUploadedFileName();
             $uploadedFilename = $this->_getResizedFilename($field, $uploadedFilename, true);
diff --git app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
index d41bf7b..2312fc6 100644
--- app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
+++ app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
@@ -567,7 +567,7 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
                 $result = $themesHelper->deleteTheme($themeId);
                 if ($result) {
                     $response = array(
-                        'message'   => $this->__('Theme has been delete.'),
+                        'message'   => $this->__('Theme has been deleted.'),
                         'themes'    => $themesHelper->getAllThemesArray(true),
                         'themeSelector' => $themesHelper->getThemesSelector(),
                         'selectedTheme' => $themesHelper->getDefaultThemeName()
@@ -1393,6 +1393,11 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
             /** @var $uploader Mage_Core_Model_File_Uploader */
             $uploader = Mage::getModel('core/file_uploader', $imageModel->getImageType());
             $uploader->setAllowRenameFiles(true)->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $result = $uploader->save(Mage_XmlConnect_Model_Images::getBasePath(), $newFileName);
             $result['thumbnail'] = Mage::getModel('xmlconnect/images')->getCustomSizeImageUrl(
                 $result['file'],
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index 8e45649..792e02f 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -119,7 +119,8 @@ Default layout, loads most of the pages
                 <block type="adminhtml/cache_notifications" name="cache_notifications" template="system/cache/notifications.phtml"></block>
                 <block type="adminhtml/notification_survey" name="notification_survey" template="notification/survey.phtml"/>
                 <block type="adminhtml/notification_security" name="notification_security" as="notification_security" template="notification/security.phtml"></block>
-            </block>
+                <block type="adminhtml/checkout_formkey" name="checkout_formkey" as="checkout_formkey" template="notification/formkey.phtml"/></block>
+                <block type="adminhtml/notification_symlink" name="notification_symlink" template="notification/symlink.phtml"/>
             <block type="adminhtml/widget_breadcrumbs" name="breadcrumbs" as="breadcrumbs"></block>
 
             <!--<update handle="formkey"/> this won't work, see the try/catch and a jammed exception in Mage_Core_Model_Layout::createBlock() -->
diff --git app/design/adminhtml/default/default/template/notification/formkey.phtml app/design/adminhtml/default/default/template/notification/formkey.phtml
new file mode 100644
index 0000000..ec99a74
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/formkey.phtml
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+/**
+ * @see Mage_Adminhtml_Block_Checkout_Formkey
+ */
+?>
+<?php if ($this->canShow()): ?>
+    <div class="notification-global notification-global-warning">
+        <strong style="color:red">Important: </strong>
+        <span>Formkey validation on checkout disabled. This may expose security risks.
+        We strongly recommend to Enable Form Key Validation On Checkout in
+        <a href="<?php echo $this->getSecurityAdminUrl(); ?>">Admin / Security Section</a>,
+        for protect your own checkout process. </span>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/notification/symlink.phtml app/design/adminhtml/default/default/template/notification/symlink.phtml
new file mode 100644
index 0000000..b606402
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/symlink.phtml
@@ -0,0 +1,34 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+/**
+ * @see Mage_Adminhtml_Block_Notification_Symlink
+ */
+?>
+<?php if ($this->isSymlinkEnabled()): ?>
+    <div class="notification-global notification-global-warning">
+        <?php echo $this->helper('adminhtml')->__('Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.')?>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/page/head.phtml app/design/adminhtml/default/default/template/page/head.phtml
index ef6371f..3f944dc 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -7,7 +7,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 </script>
 
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index 4241c9c..9ffceb7 100644
--- app/design/frontend/base/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/cart/shipping.phtml
@@ -109,6 +109,7 @@
             <div class="buttons-set">
                 <button type="submit" title="<?php echo $this->__('Update Total') ?>" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
             </div>
+            <?php echo $this->getBlockHtml('formkey') ?>
         </form>
         <?php endif; ?>
         <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/multishipping/billing.phtml app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
index 870e758..b158931 100644
--- app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
@@ -91,6 +91,7 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Review Your Order') ?>" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
     <script type="text/javascript">
     //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
index a7d38c9..2601bd6 100644
--- app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
@@ -126,5 +126,6 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Billing Information') ?>" class="button"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/billing.phtml app/design/frontend/base/default/template/checkout/onepage/billing.phtml
index 8e3f19f..eab3b17 100644
--- app/design/frontend/base/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/billing.phtml
@@ -201,6 +201,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index b4a4428..e9d0830 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -35,6 +35,7 @@
 <form action="" id="co-payment-form">
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping.phtml app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
index 39428ba..d5071ff 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
@@ -141,6 +141,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
index c07f071..00864ed 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
index c76e993..ff45115 100644
--- app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
@@ -199,6 +199,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
index 0a449d0..3c56896 100644
--- app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
@@ -103,6 +103,7 @@
         <div class="buttons-set">
             <button type="submit" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
index aac2407..0644c14 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
@@ -77,5 +77,6 @@
         <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shopping Cart') ?></a></p>
         <button type="submit" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
index e7470f5..0844e1b 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
@@ -92,6 +92,7 @@
     <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
     <button type="submit" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
 </div>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 </div>
 <script type="text/javascript">
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
index bb9c69b..b62974c 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
@@ -117,5 +117,6 @@
         <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
         <button  class="button" type="submit"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
index cbdd161..aa161ea 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
@@ -224,6 +224,7 @@
     </span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
index 38e4e36..44a1b6d 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
@@ -36,6 +36,7 @@
     <fieldset>
         <?php echo $this->getChildChildHtml('methods_additional', '', true, true) ?>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
index 579b75b..06e9bb6 100644
--- app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
+++ app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
@@ -92,7 +92,7 @@
         } else {
             var elements = Form.getElements(this.form);
             for (var i=0; i<elements.length; i++) {
-                if (elements[i].name == 'payment[method]') {
+                if (elements[i].name == 'payment[method]' || elements[i].name == 'form_key') {
                     elements[i].disabled = false;
                 }
             }
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
index 5f4f7fb..dc653e6 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
@@ -38,7 +38,7 @@
         <script type="text/javascript">
         //<![CDATA[
             Form.getElements('multishipping-billing-form').each(function(elem){
-                if (elem.name == 'payment[method]' && elem.value == 'free') {
+                if ((elem.name == 'payment[method]' && elem.value == 'free') || elements[i].name == 'form_key') {
                     elem.checked = true;
                     elem.disabled = false;
                     elem.parentNode.show();
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
index 517bc19..069ede6 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
@@ -35,6 +35,7 @@ function enablePaymentMethods(free) {
             if (elements[i].name == 'payment[method]'
                 || elements[i].name == 'payment[use_customer_balance]'
                 || elements[i].name == 'payment[use_reward_points]'
+                || elements[i].name == 'form_key'
             ) {
                 methodName = elements[i].value;
                 if ((free && methodName == 'free') || (!free && methodName != 'free')) {
diff --git app/design/frontend/enterprise/default/template/invitation/form.phtml app/design/frontend/enterprise/default/template/invitation/form.phtml
index 22a9b96..ecf69d9 100644
--- app/design/frontend/enterprise/default/template/invitation/form.phtml
+++ app/design/frontend/enterprise/default/template/invitation/form.phtml
@@ -36,6 +36,7 @@
 <?php echo $this->getChildHtml('form_before')?>
 <?php if ($maxPerSend = (int)Mage::helper('enterprise_invitation')->getMaxInvitationsPerSend()): ?>
 <form id="invitationForm" action="" method="post">
+    <?php echo $this->getBlockHtml('formkey'); ?>
     <div class="fieldset">
     <h2 class="legend"><?php echo Mage::helper('enterprise_invitation')->__('Invite your friends by entering their email addresses below'); ?></h2>
         <ul class="form-list">
diff --git app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml
index 9ded1c6..7382d46 100644
--- app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml
@@ -225,6 +225,7 @@
     </span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/etc/config.xml app/etc/config.xml
index 3b90ef7..8ef968e 100644
--- app/etc/config.xml
+++ app/etc/config.xml
@@ -140,6 +140,11 @@
                 <export>{{var_dir}}/export</export>
             </filesystem>
         </system>
+        <dev>
+            <template>
+                <allow_symlink>0</allow_symlink>
+            </template>
+        </dev>
         <general>
             <locale>
                 <code>en_US</code>
diff --git app/etc/modules/Enterprise_PageCache.xml app/etc/modules/Enterprise_PageCache.xml
index bb8df52..bc9a34d 100644
--- app/etc/modules/Enterprise_PageCache.xml
+++ app/etc/modules/Enterprise_PageCache.xml
@@ -32,6 +32,7 @@
             <codePool>core</codePool>
             <depends>
                 <Mage_Core/>
+                <Mage_Tax/>
             </depends>
         </Enterprise_PageCache>
     </modules>
diff --git app/locale/en_US/Enterprise_Invitation.csv app/locale/en_US/Enterprise_Invitation.csv
index 08c3417..24c7fdf 100644
--- app/locale/en_US/Enterprise_Invitation.csv
+++ app/locale/en_US/Enterprise_Invitation.csv
@@ -122,3 +122,5 @@
 "You cannot send more invitations","You cannot send more invitations"
 "Your invitation is not valid. Please contact us at %s.","Your invitation is not valid. Please contact us at %s."
 "Your invitation is not valid. Please create an account.","Your invitation is not valid. Please create an account."
+"Invitations limit exceeded. Please try again later.","Invitations limit exceeded. Please try again later."
+"Minimum Interval between invites(minutes)","Minimum Interval between invites(minutes)"
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 86d7661..9a7d719 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1195,3 +1195,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 5af0ae3..1081a6b 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -390,3 +390,4 @@
 "You will have to log in after you save your custom admin path.","You will have to log in after you save your custom admin path."
 "Your design change for the specified store intersects with another one, please specify another date range.","Your design change for the specified store intersects with another one, please specify another date range."
 "database ""%s""","database ""%s"""
+"Invalid image.","Invalid image."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 7169fae..50bac5f 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -30,3 +30,4 @@
 "hours","hours"
 "minute","minute"
 "minutes","minutes"
+"Backend name "Static" not supported.","Backend name "Static" not supported."
diff --git app/locale/en_US/Mage_XmlConnect.csv app/locale/en_US/Mage_XmlConnect.csv
index 92851c0..6b515d7 100644
--- app/locale/en_US/Mage_XmlConnect.csv
+++ app/locale/en_US/Mage_XmlConnect.csv
@@ -984,7 +984,7 @@
 "The value should not be less than %.2f!","The value should not be less than %.2f!"
 "Theme configurations are successfully reset.","Theme configurations are successfully reset."
 "Theme has been created.","Theme has been created."
-"Theme has been delete.","Theme has been delete."
+"Theme has been deleted.","Theme has been deleted."
 "Theme label can\'t be empty","Theme label can\'t be empty"
 "Theme label:","Theme label:"
 "Theme name is not set.","Theme name is not set."
diff --git downloader/Maged/Connect.php downloader/Maged/Connect.php
index a1170a4..1715e91 100644
--- downloader/Maged/Connect.php
+++ downloader/Maged/Connect.php
@@ -396,7 +396,9 @@ class Maged_Connect
      */
     protected function _consoleHeader() {
         if (!$this->_consoleStarted) {
-?>
+            $validateKey = md5(time());
+            $sessionModel = new Maged_Model_Session();
+            $sessionModel->set('validate_cache_key', $validateKey); ?>
 <html><head><style type="text/css">
 body { margin:0px;
     padding:3px;
@@ -442,6 +444,7 @@ function clear_cache(callbacks)
     var intervalID = setInterval(function() {show_message('.', false); }, 500);
     var clean = 0;
     var maintenance = 0;
+    var validate_cache_key = '<?php echo $validateKey; ?>';
     if (window.location.href.indexOf('clean_sessions') >= 0) {
         clean = 1;
     }
@@ -451,7 +454,7 @@ function clear_cache(callbacks)
 
     new top.Ajax.Request(url, {
         method: 'post',
-        parameters: {clean_sessions:clean, maintenance:maintenance},
+        parameters: {clean_sessions:clean, maintenance:maintenance, validate_cache_key:validate_cache_key},
         onCreate: function() {
             show_message('Cleaning cache');
             show_message('');
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index e954c5a..7958589 100644
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -417,7 +417,7 @@ final class Maged_Controller
      */
     public function cleanCacheAction()
     {
-        $result = $this->cleanCache();
+        $result = $this->cleanCache(true);
         echo json_encode($result);
     }
 
@@ -945,25 +945,36 @@ final class Maged_Controller
         }
     }
 
-    protected function cleanCache()
+    /**
+     * Clean cache
+     *
+     * @param bool $validate
+     * @return array
+     */
+    protected function cleanCache($validate = false)
     {
         $result = true;
         $message = '';
         try {
             if ($this->isInstalled()) {
-                if (!empty($_REQUEST['clean_sessions'])) {
-                    Mage::app()->cleanAllSessions();
-                    $message .= 'Session cleaned successfully. ';
+                if ($validate) {
+                    $result = $this->session()->validateCleanCacheKey();
+                }
+                if ($result) {
+                    if (!empty($_REQUEST['clean_sessions'])) {
+                        Mage::app()->cleanAllSessions();
+                        $message .= 'Session cleaned successfully. ';
+                    }
+                    Mage::app()->cleanCache();
+
+                    // reinit config and apply all updates
+                    Mage::app()->getConfig()->reinit();
+                    Mage_Core_Model_Resource_Setup::applyAllUpdates();
+                    Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
+                    $message .= 'Cache cleaned successfully';
+                } else {
+                    $message .= 'Validation failed';
                 }
-                Mage::app()->cleanCache();
-
-                // reinit config and apply all updates
-                Mage::app()->getConfig()->reinit();
-                Mage_Core_Model_Resource_Setup::applyAllUpdates();
-                Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
-                $message .= 'Cache cleaned successfully';
-            } else {
-                $result = true;
             }
         } catch (Exception $e) {
             $result = false;
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index 6faeba4..6cf1b9b 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -82,6 +82,20 @@ class Maged_Model_Session extends Maged_Model
     }
 
     /**
+     * Unset value by key
+     *
+     * @param string $key
+     * @return $this
+     */
+    public function delete($key)
+    {
+        if (isset($_SESSION[$key])) {
+            unset($_SESSION[$key]);
+        }
+        return $this;
+    }
+
+    /**
      * Authentication to downloader
      */
     public function authenticate()
@@ -254,4 +268,24 @@ class Maged_Model_Session extends Maged_Model
         }
         return true;
     }
+
+    /**
+     * Validate key for cache cleaning
+     *
+     * @return bool
+     */
+    public function validateCleanCacheKey()
+    {
+        $result = false;
+        $validateKey = $this->get('validate_cache_key');
+        if ($validateKey
+            && !empty($_REQUEST['validate_cache_key'])
+            && $validateKey == $_REQUEST['validate_cache_key']
+        ) {
+            $result = true;
+        }
+        $this->delete('validate_cache_key');
+
+        return $result;
+    }
 }
diff --git js/varien/payment.js js/varien/payment.js
index c154910..077a27e 100644
--- js/varien/payment.js
+++ js/varien/payment.js
@@ -31,7 +31,7 @@ paymentForm.prototype = {
 
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
diff --git skin/frontend/base/default/js/opcheckout.js skin/frontend/base/default/js/opcheckout.js
index 8632f43..996dc93 100644
--- skin/frontend/base/default/js/opcheckout.js
+++ skin/frontend/base/default/js/opcheckout.js
@@ -711,7 +711,7 @@ Payment.prototype = {
         }
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name == 'form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
diff --git skin/frontend/enterprise/default/js/opcheckout.js skin/frontend/enterprise/default/js/opcheckout.js
index 51f4f36..d698583 100644
--- skin/frontend/enterprise/default/js/opcheckout.js
+++ skin/frontend/enterprise/default/js/opcheckout.js
@@ -707,7 +707,7 @@ Payment.prototype = {
         var elements = Form.getElements(this.form);
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
