WITH
    unique_products
        AS (
               SELECT DISTINCT
                   sku --The idea here is to get a list of all of our products of all time across systems, as certain ones are mising older products
               FROM
                   (
                       SELECT
                           sku
                       FROM
                           SHIPSTATION_PORTABLE.SHIPSTATION_PRODUCTS_8589936627
                       UNION ALL
                       SELECT
                           sku
                       FROM
                           stord.STORD_PRODUCTS_8589936822
                       UNION ALL
                       SELECT
                           itemid
                       FROM
                           netsuite.item
                       UNION ALL
                       SELECT
                           sku
                       FROM
                           staging.shopify_products
                   )
           )
  , assembly_aggregate
        AS (
               SELECT
                   parentitem
                 , SUM(quantity) AS assembly_quantity
               FROM
                   netsuite.itemmember
               GROUP BY
                   parentitem
               HAVING
                   assembly_quantity IS NOT NULL
           )
  , actual_ns_products
        AS (
               SELECT
                   *
               FROM
                   netsuite.item
               WHERE
                   itemtype IN (--This is so that we can filter NS pre-emptively for all the actual products we wanna see, rather than the whole query
                                'InvtPart',
                                'Assembly',
                                'OthCharge',
                                'NonInvtPart',
                                'Payment'
                       )
           )
SELECT DISTINCT
    unique_products.sku
  , i.id                                                           AS product_id_edw
  , i.id                                                           AS item_id_ns
  , stord.id                                                       AS item_id_stord                                                          AS product_id_d2c_shopify
  , case
        when shop_prod.shopify_store = 'd2c'
            then shop_prod.product_id
    end                                                            AS product_id_d2c_shopify
  , case
        when shop_prod.shopify_store = 'b2b'
            then shop_prod.product_id
    end                                                            AS product_id_b2b_shopify
  , case
        when shop_prod.shopify_store = 'goodrwill'
            then shop_prod.product_id
    end                                                            AS product_id_goodrwill_shopify
  , case
        when shop_prod.shopify_store = 'd2c_can'
            then shop_prod.product_id
    end                                                            AS product_id_d2c_can_shopify
  , case
        when shop_prod.shopify_store = 'b2b_can'
            then shop_prod.product_id
    end                                                            AS product_id_b2b_can_shopify
  , case
        when shop_prod.shopify_store = 'd2c'
            then shop_prod.inventory_item_id
    end                                                            AS inventory_item_id_d2c_shopify
  , case
        when shop_prod.shopify_store = 'b2b'
            then shop_prod.inventory_item_id
    end                                                            AS inventory_item_id_b2b_shopify
  , case
        when shop_prod.shopify_store = 'goodrwill'
            then shop_prod.inventory_item_id
    end                                                            AS inventory_item_id_goodrwill_shopify
  , case
        when shop_prod.shopify_store = 'd2c_can'
            then shop_prod.inventory_item_id
    end                                                            AS inventory_item_id_d2c_can_shopify
  , case
        when shop_prod.shopify_store = 'b2b_can'
            then shop_prod.inventory_item_id
    end                                                            AS inventory_item_id_b2b_can_shopify
  , shipstation.productid                                          AS item_id_shipstation
  , i.displayname                                                  AS display_name
  , i.itemtype                                                     AS item_type
  , i.custitem5                                                    AS collection
  , family.name                                                    AS family
  , stage.name                                                     AS stage
  , i.fullname                                                     AS full_name
  , class.name                                                     AS merchandise_class
  , dept.name                                                      AS merchandise_department
  , division.name                                                  AS merchandise_division
  , i.upccode                                                      AS upc_code
  , i.custitemold_upc_code                                         AS old_upc_code
  , i.CUSTITEM18                                                   AS lens_sku
  , i.vendorname                                                   AS vendor_name
  , i.custitem19                                                   AS logo_sku
  , framecolor.name                                                AS color_frame
  , templecolor.name                                               AS color_temple
  , framefinish.name                                               AS finish_frame
  , templefinish.name                                              AS finish_temple
  , lenscolor.name                                                 AS color_lens_finish
  , i.custitem24                                                   AS lens_type
  , design.name                                                    AS design_tier
  , artwork.name                                                   AS frame_artwork
  , i.custitem7                                                    AS d2c_launch_timestamp
  , DATE(i.custitem7)                                              AS d2c_launch_date
  , i.custitem16                                                   AS b2b_launch_timestamp
  , DATE(i.custitem16)                                             AS b2b_launch_date
  , i.custitem_goodr_mc_ip_qty                                     AS mc_quantity
  , i.custitem_goodr_mc_weight                                     AS mc_weight_oz
  , i.custitem_goodr_mc_length                                     AS mc_length_in
  , i.custitem_goodr_mc_width                                      AS mc_width_in
  , i.custitem_goodr_item_height                                   AS mc_height_in
  , i.custitem3                                                    AS ip_weight_oz
  , i.custitem_goodr_ip_length                                     AS ip_length_in
  , i.custitem_good_ip_width                                       AS ip_width_in
  , i.custitem_goodr_ip_height                                     AS ip_height_in
  , i.custitem_goodr_hts_code_item                                 AS hts_code
  , i.CUSTITEM1                                                    AS country_of_origin
  , CASE WHEN i.custitem_stord_item = 'T' THEN TRUE ELSE FALSE END AS stord_item_flag
  , CASE WHEN i.custitem14 = 'T' THEN TRUE ELSE FALSE END          AS distributor_portal_item_flag
  , CASE WHEN i.custitem25 = 'T' THEN TRUE ELSE FALSE END          AS key_account_prebook_item_flag
  , CASE WHEN i.custitem27 = 'T' THEN TRUE ELSE FALSE END          AS replenish_flag
  , CASE
        WHEN i.custitemmozard_gp_flag = 'T'
            THEN TRUE
        ELSE FALSE
    END                                                            AS free_shit_flag
  , assembly_quantity
  , CAST(
            CASE
                WHEN LEFT(i.itemid, 2) = 'GC'
                    THEN SPLIT_PART(i.itemid, '-', 2)
            END AS int
    )                                                              AS gift_card_amount
  , i.incomeaccount                                                AS account_id_ns
  , ga.account_number
  , ga.account_display_name
FROM
    unique_products
    LEFT OUTER JOIN actual_ns_products                             i
        ON i.itemid = unique_products.sku
    LEFT OUTER JOIN dim.gl_account                                 ga
        ON i.incomeaccount = ga.account_id_ns
    LEFT JOIN netsuite.customlist991                               framecolor
        ON i.custitem20 = framecolor.id
    LEFT JOIN netsuite.customlist991                               templecolor
        ON i.custitem32 = templecolor.id
    LEFT JOIN netsuite.customlist988                               framefinish
        ON i.custitem21 = framefinish.id
    LEFT JOIN netsuite.customlist988                               templefinish
        ON i.custitem33 = templefinish.id
    LEFT JOIN netsuite.customlist_psgss_product_color              lenscolor
        ON i.custitem22 = lenscolor.id
    LEFT JOIN netsuite.customlist_psgss_product_color              lenscolorbase
        ON i.custitem28 = lenscolorbase.id
    LEFT JOIN netsuite.customlist_psgss_merc_class                 class
        ON i.custitem_psgss_merc_class = class.id
    LEFT JOIN netsuite.customlist_psgss_merc_dept                  dept
        ON i.custitem_psgss_merc_dept = dept.id
    LEFT JOIN netsuite.customlist_psgss_merc_division              division
        ON i.custitem_psgss_merc_division = division.id
    LEFT JOIN netsuite.customlist894                               family
        ON i.custitem4 = family.id
    LEFT JOIN netsuite.customlist896                               stage
        ON i.custitem6 = stage.id
    LEFT JOIN netsuite.customlist987                               design
        ON i.custitem17 = design.id
    LEFT JOIN netsuite.customlist1271                              artwork
        ON i.custitem30 = artwork.id
    LEFT JOIN assembly_aggregate                                   agg
        ON i.id = agg.parentitem
    LEFT JOIN staging.shopify_products                             shop_prod
        ON shop_prod.sku = unique_products.sku
    LEFT JOIN stord.stord_products_8589936822                      stord
        ON stord.sku = unique_products.sku
    LEFT JOIN shipstation_portable.shipstation_products_8589936627 shipstation
        ON shipstation.sku = unique_products.sku





