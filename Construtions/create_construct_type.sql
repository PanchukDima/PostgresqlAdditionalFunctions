CREATE OR REPLACE PROCEDURE public.create_construct_type(p_oid oid)
 LANGUAGE plpgsql
AS $procedure$
    declare 
    
    l_type public.type_info;
    l_array_typcategory text[];
    l_construct_attr text := '';
    l_construct_attr_param text :='';
    l_query text;

	BEGIN
        select array_agg((select pta.typcategory  from pg_catalog.pg_type pta where pta."oid" = pa.atttypid))
                       into l_array_typcategory
                       from pg_catalog.pg_type pt
                  left join pg_catalog.pg_attribute pa
                         on pa.attrelid = pt.typrelid
                       join pg_catalog.pg_namespace pn
                         on pn."oid" = pt.typnamespace
                      where pt.oid = p_oid;
                  
                   select   pt.typname
                            ,pn.nspname 
                            ,array_agg((pa.attname, (select pta.typname  from pg_catalog.pg_type pta where pta."oid" = pa.atttypid))::public.type_attr) as attrs
                      into l_type
                      from pg_catalog.pg_type pt
                 left join pg_catalog.pg_attribute pa
                        on pa.attrelid = pt.typrelid
                      join pg_catalog.pg_namespace pn
                        on pn."oid" = pt.typnamespace
                     where pt.oid = p_oid
                     GROUP BY pt.typname
                              ,pn.nspname;
                
                select string_agg(concat('p_',t.name,' ' ,t.type), ', ')
                       ,string_agg(concat('p_',t.name), ', ')
                into l_construct_attr
                     ,l_construct_attr_param
                from unnest(l_type.attrs) t;
                 if l_array_typcategory && array['A'] and coalesce(array_length(l_array_typcategory, 1), 0) = 1 then
                 l_query := 'CREATE OR REPLACE FUNCTION '||l_type.typnspname||'.'||l_type.typname||'(VARIADIC '||l_construct_attr||')
                           RETURNS '||l_type.attrs[1].type||'
                           LANGUAGE plpgsql
                           AS $$
                           BEGIN
                                RETURN (row('||l_construct_attr_param||')::'||l_type.typnspname||'.'||l_type.typname||').'||l_type.typname||';
                           END;$$;';
                 ELSE
                           
                    
                 l_query := 'CREATE OR REPLACE FUNCTION '||l_type.typnspname||'.'||l_type.typname||'('||l_construct_attr||')
                           RETURNS '||l_type.typnspname||'.'||l_type.typname||'
                           LANGUAGE plpgsql
                           AS $$
                           BEGIN
                                RETURN ('||l_construct_attr_param||')::'||l_type.typnspname||'.'||l_type.typname||';
                           END;$$;';
                  end IF;
                       
                 execute l_query;
	END;
$procedure$
;
