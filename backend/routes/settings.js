const express = require('express');
const Setting = require('../models/Setting');
const { protect, admin } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/settings/public
// @access  Public - التطبيق بياخد منه اسم المتجر والعملة وبيانات التواصل
router.get('/public', async (req, res) => {
  try {
    const settings = await Setting.getSettings();
    res.json({
      storeName: settings.storeName,
      currency: settings.currency,
      shippingFee: settings.shippingFee,
      freeShippingThreshold: settings.freeShippingThreshold,
      shippingNote: settings.shippingNote,
      contactPhone: settings.contactPhone,
      contactEmail: settings.contactEmail,
      welcomeMessage: settings.welcomeMessage,
      whatsappNumber: settings.whatsappNumber,
      paymentMethods: {
        etisalatCash: {
          number: settings.etisalatCashNumber,
          name: settings.etisalatCashName,
        },
        instapay: {
          handle: settings.instapayHandle,
        },
        bankTransfer: {
          bankName: settings.bankName,
          accountName: settings.bankAccountName,
          accountNumber: settings.bankAccountNumber,
        },
      },
    });
  } catch (error) {
    console.error('Get public settings error:', error);
    res.status(500).json({ message: 'خطأ في جلب الإعدادات' });
  }
});

// @route   GET /api/settings
// @access  Admin
router.get('/', protect, admin, async (req, res) => {
  try {
    const settings = await Setting.getSettings();
    res.json({ settings });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({ message: 'خطأ في جلب الإعدادات' });
  }
});

// @route   PUT /api/settings
// @access  Admin
router.put('/', protect, admin, async (req, res) => {
  try {
    const allowedFields = [
      'storeName', 'currency', 'shippingFee', 'freeShippingThreshold',
      'shippingNote', 'contactPhone', 'contactEmail', 'lowStockThreshold', 'welcomeMessage',
      'whatsappNumber', 'etisalatCashNumber', 'etisalatCashName',
      'instapayHandle', 'bankName', 'bankAccountName', 'bankAccountNumber'
    ];
    const updates = {};
    for (const key of allowedFields) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }
    const settings = await Setting.updateSettings(updates);
    res.json({ settings, message: 'تم تحديث الإعدادات بنجاح' });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ message: 'خطأ في تحديث الإعدادات' });
  }
});

module.exports = router;
